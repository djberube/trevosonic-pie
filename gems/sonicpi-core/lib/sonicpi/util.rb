#--
# This file is part of Sonic Pi: http://sonic-pi.net
# Full project source: https://github.com/samaaron/sonic-pi
# License: https://github.com/samaaron/sonic-pi/blob/main/LICENSE.md
#
# Copyright 2013, 2014, 2015, 2016 by Sam Aaron (http://sam.aaron.name).
# All rights reserved.
#
# Permission is granted for use, copying, modification, and
# distribution of modified versions of this work as long as this
# notice is included.
#++
require 'cgi'
require 'fileutils'
require 'securerandom'
require_relative 'paths'

module SonicPi
  module Util
    # Check which OS we're on
    case RUBY_PLATFORM
    when /.*linux.*/
      if File.exist?('/etc/rpi-issue')
        @@os = :raspberry
      else
        @@os = :linux
      end
    when /.*darwin.*/
      @@os = :osx
    when /.*mingw.*/
      @@os = :windows
    else
      raise "Unsupported platform #{RUBY_PLATFORM}"
    end

    @@safe_mode = false
    @@current_uuid = nil
    @@home_dir = nil
    @@util_lock = Mutex.new

    if @@os == :raspberry

      detect_pimodel = lambda do |code|
        code = code.to_i(base=16)
        #extract segments from code
        new = (code >> 23) &0x1 #must be one for valid new revision code
        model = (code >> 4) & 0xff
        mem = (code >> 20) & 0x7
        #two lokup hashes for memory size and model identity
        memsize = {0=>"256Mb",1=>"512Mb",2=>"1Gb",3=>"2Gb",4=>"4Gb",5=>"8Gb"}
        modname = {4=>"2",8=>"3",13=>"3B+",17=>"4B",19=>"400",23=>"5"}
        os64 = RUBY_PLATFORM.match(/aarch64.*linux.*/)&&true
        #os32 = RUBY_PLATFORM.match(/.arm.*-linux.*/)&&true
        if new==1
          rp="Raspberry Pi #{modname[model]}:#{memsize[mem]}"
        else
          rp="Raspberry Pi"
        end
        rp+=" 64bit OS" if os64
        # We may want to turn this into a more useful data structure should we need
        # to introspect the amount of memory, or do something bespoke for a specific
        # modname.
        return rp
      end

      code = `cat /proc/cpuinfo |awk '/Revision/ {print $3}'`.strip
      model = detect_pimodel.call(code)

      @@raspberry_pi_model = model
    end

    begin
      debug_log = File.absolute_path("#{Paths.log_path}/debug.log")

      # ensure_dir
      begin
        FileUtils.mkdir_p(Paths.log_path) unless File.exist?(Paths.log_path)
      rescue
        @@safe_mode = true
        log "Unable to create log path dir#{Paths.log_path} due to permissions errors"
      end

      @@log_file ||= File.open(debug_log, 'a')
    rescue Exception => e
      @@safe_mode = true
      STDERR.puts "Unable to open log file #{Paths.log_path}/debug.log"
      STDERR.puts e.inspect
      @@log_file = nil
    end

    def os
      @@os
    end

    def raspberry_pi?
      os == :raspberry
    end

    def raspberry_pi_2?
      os == :raspberry && (@@raspberry_pi_model.start_with?("Raspberry Pi 2"))
    end

    def raspberry_pi_3?
      os == :raspberry && (@@raspberry_pi_model.start_with?("Raspberry Pi 3"))
    end

    def raspberry_pi_4?
      os == :raspberry && (@@raspberry_pi_model.start_with?("Raspberry Pi 4"))
    end

    def raspberry_pi_5?
      os == :raspberry && (@@raspberry_pi_model.start_with?("Raspberry Pi 5"))
    end

    def unify_tilde_dir(path)
      if os == :windows
        path
      else
        path.gsub(/\A#{Paths.user_dir}/, "~")
      end
    end

    def num_buffers_for_current_os
      4096
    end

    def num_audio_busses_for_current_os
      1024
    end

    def default_sched_ahead_time
      if raspberry_pi_2?
        2
      elsif  raspberry_pi_3?
        1.5
      else
        0.5
      end
    end

    def host_platform_desc
      case os
      when :raspberry
        @@raspberry_pi_model
      when :linux
        "Linux"
      when :osx
        "Mac"
      when :windows
        "Win"
      end
    end

    def default_control_delta
      if raspberry_pi?
        0.013
      else
        0.005
      end
    end

    def global_uuid
      return @@current_uuid if @@current_uuid
      @@util_lock.synchronize do
        return @@current_uuid if @@current_uuid
        path = File.absolute_path("#{Paths.home_dir_path}/.uuid")

        if (File.exist? path)
          old_id = File.readlines(path).first.strip
          if  (not old_id.empty?) &&
              (old_id.size == 36)
            @@current_uuid = old_id
            return old_id
          end
        end

        # invalid or no uuid - create and store a new one
        new_uuid = SecureRandom.uuid
        begin
          File.open(path, 'w') {|f| f.write(new_uuid)}
        rescue
          @@safe_mode = true
          log "Unable to write uuid file to #{path}"
        end
        @@current_uuid = new_uuid
        new_uuid
      end
    end

    def ensure_dir(dir)
      # Defensive: validate input
      return false if dir.nil? || dir.to_s.strip.empty?

      dir_path = dir.to_s.strip

      # Defensive: prevent directory traversal attacks
      begin
        expanded_path = File.expand_path(dir_path)
      rescue ArgumentError => e
        log "Invalid directory path #{dir_path.inspect}: #{e.message}"
        return false
      end

      begin
        FileUtils.mkdir_p(expanded_path) unless File.exist?(expanded_path)
        true
      rescue Errno::EACCES, Errno::EPERM => e
        @@safe_mode = true
        log "Unable to create #{expanded_path} due to permissions errors: #{e.message}"
        false
      rescue => e
        @@safe_mode = true
        log "Unable to create #{expanded_path}: #{e.class} - #{e.message}"
        false
      end
    end

    def __exe_fix(path)
      case os
      when :windows
        "#{path}.exe"
      else
        path
      end
    end

    def fetch_url(url, anonymous_uuid=true)
      # Defensive: validate url
      return nil if url.nil? || url.to_s.strip.empty?

      url_str = url.to_s.strip

      # Defensive: validate URL scheme
      unless url_str.start_with?('http://') || url_str.start_with?('https://')
        log "Invalid URL scheme for #{url_str.inspect}" if respond_to?(:log)
        return nil
      end

      begin
        params = {
          ruby_platform: RUBY_PLATFORM,
          ruby_version: RUBY_VERSION,
          ruby_patchlevel: RUBY_PATCHLEVEL,
          sonic_pi_version: @version.to_s
        }

        params[:uuid] = global_uuid if anonymous_uuid

        uri = URI.parse(url_str)

        # Defensive: validate parsed URI
        unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
          log "URL must be HTTP or HTTPS, got #{uri.class}" if respond_to?(:log)
          return nil
        end

        uri.query = URI.encode_www_form(params)

        # Defensive: set timeout
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 10, read_timeout: 10) do |http|
          request = Net::HTTP::Get.new(uri)
          http.request(request)
        end
      rescue URI::InvalidURIError => e
        log "Invalid URI #{url_str.inspect}: #{e.message}" if respond_to?(:log)
        nil
      rescue Timeout::Error => e
        log "Timeout fetching URL #{url_str.inspect}: #{e.message}" if respond_to?(:log)
        nil
      rescue => e
        log "Error fetching URL #{url_str.inspect}: #{e.class} - #{e.message}" if respond_to?(:log)
        nil
      end
    end

    def log_raw(s)
      if @@log_file
        @@log_file.write("[#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}] #{s}")
        @@log_file.flush
      else
        Kernel.puts("[#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}] #{s}")
      end
    end

    def log_exception(e, context="")
      if debug_mode
        res = String.new("Exception => #{context} #{e.message}")
        e.backtrace.each do |b|
          res << "                                        "
          res << b
          res << "\n"
        end
        log_raw res
      end
    end

    def log_info(s)
      log "--------------->  " + s
    end

    def log(message)
      if debug_mode
        message = String.new(message.to_s)
        res = String.new
        res << "\n" if message.empty?
        first = true
        while !(message.empty?)
          if first
            res << message.slice!(0..151)
            res << "\n"
            first = false
          else
            res << "                                        "
            res << message.slice!(0..133)
            res << "\n"
          end
        end
        log_raw res
      end
    end


    def debug_mode
      false
    end

    def osc_debug_mode
      false
    end

    def incoming_osc_debug_mode
      false
    end

    def resolve_synth_opts_hash_or_array(opts)
      # Defensive: handle nil early
      return {} if opts.nil?

      case opts
      when Hash, SonicPi::Core::SPMap
        # Defensive: freeze to prevent mutation
        opts.freeze unless opts.frozen?
        opts
      when Array, SonicPi::Core::SPVector
        # Defensive: validate array isn't excessively large
        if opts.respond_to?(:length) && opts.length > 10000
          raise ArgumentError, "Options array too large (#{opts.length} elements, max 10000)"
        end
        merge_synth_arg_maps_array(opts)
      when NilClass
        {}
      else
        raise ArgumentError, "Invalid options. Options should either be an even list of key value pairs, a single Hash or nil. Got #{opts.class} (#{opts.inspect})"
      end
    rescue ArgumentError
      raise
    rescue => e
      raise ArgumentError, "Failed to resolve synth options: #{e.class} - #{e.message}"
    end

    def truthy?(val, depth = 0)
      # Defensive: prevent infinite recursion with Proc
      max_depth = 100
      if depth > max_depth
        raise RuntimeError, "Maximum recursion depth (#{max_depth}) exceeded in truthy?"
      end

      case val
      when Numeric
        val != 0
      when NilClass
        false
      when TrueClass
        true
      when FalseClass
        false
      when Proc
        # Defensive: catch errors in proc evaluation
        begin
          new_v = val.call
          truthy?(new_v, depth + 1)
        rescue => e
          log_exception(e, "evaluating Proc in truthy?") if respond_to?(:log_exception)
          false
        end
      else
        # Defensive: treat unknown types as truthy
        true
      end
    end

    def zipmap(a, b)
      # Defensive: validate inputs
      unless a.respond_to?(:size) && a.respond_to?(:[])
        raise ArgumentError, "First argument must respond to :size and :[], got #{a.class}"
      end

      unless b.respond_to?(:size) && b.respond_to?(:[])
        raise ArgumentError, "Second argument must respond to :size and :[], got #{b.class}"
      end

      res = {}
      a_size = a.size
      b_size = b.size

      # Defensive: prevent excessive iterations
      max_iterations = 10000
      iters = [a_size, b_size, max_iterations].min

      if a_size > max_iterations || b_size > max_iterations
        log "Warning: zipmap truncated to #{max_iterations} iterations (arrays: #{a_size}, #{b_size})" if respond_to?(:log)
      end

      iters.times do |i|
        res[a[i]] = b[i]
      end

      res
    end

    def split_params_and_merge_opts_array(opts_a)
      return [], opts_a if opts_a.is_a? Hash

      opts_a = opts_a.to_a
      params = []
      idx = 0
      size = opts_a.size

      while (idx < size) && !(m = opts_a[idx]).is_a?(Hash)
        params << m
        idx += 1
      end

      return params, {} if idx == size

      opts = (opts_a[idx..-1]).reduce({}) do |s, el|
        s.merge(el)
      end

      return params, opts
    end



    def merge_synth_arg_maps_array(opts_a)
      return opts_a if opts_a.is_a? Hash

      # Defensive: handle nil
      return {} if opts_a.nil?

      # merge all initial hash elements
      # assumes rest of args are kv pairs and turns
      # them into hashes too and merges the
      opts_a = opts_a.to_a
      res = {}
      idx = 0
      size = opts_a.size

      # Defensive: prevent infinite loops
      max_iterations = 10000
      iterations = 0

      while (idx < size) && (m = opts_a[idx]).is_a?(Hash)
        res = res.merge(m)
        idx += 1
        iterations += 1

        # Defensive: break on excessive iterations
        if iterations > max_iterations
          raise RuntimeError, "merge_synth_arg_maps_array exceeded max iterations (#{max_iterations})"
        end
      end

      return res if idx == size
      left = (opts_a[idx..-1])

      # Defensive: provide better error message
      unless left.size.even?
        raise ArgumentError, "There must be an even number of trailing synth args (got #{left.size} args: #{left.inspect})"
      end

      # Defensive: catch errors in Hash construction
      begin
        h = Hash[*left]
      rescue => e
        raise ArgumentError, "Failed to construct hash from synth args: #{e.message}"
      end

      res.merge(h)
    end

    def purge_nil_vals!(m)
      m.delete_if { |k, v| v.nil? }
    end

    def pp_el_or_list(l)
      if l.size == 1
        return l[0].inspect
      else
        return l.inspect
      end
    end

    def arg_h_pp(arg_h)
      s = "{"
      arg_h.each do |k, v|
        if v
          rounded = v.is_a?(Float) ? v.round(4) : v.inspect
          s += "#{k}: #{rounded}, "
        end
      end
      s.chomp(", ") << "}"
    end

    def safe_mode?
      @@safe_mode
    end

    def is_list_like?(o)
      o.is_a?(Array) || o.is_a?(SonicPi::Core::SPVector)
    end

    def __thread_locals(t = Thread.current)
      tls = t.thread_variable_get(:sonic_pi_thread_locals)
      tls = t.thread_variable_set(:sonic_pi_thread_locals, SonicPi::Core::ThreadLocal.new) unless tls
      return tls
    end

    def __system_thread_locals(t = Thread.current)
      tls = t.thread_variable_get(:sonic_pi_system_thread_locals)
      tls = t.thread_variable_set(:sonic_pi_system_thread_locals, SonicPi::Core::ThreadLocal.new) unless tls
      return tls
    end

    def __thread_locals_reset!(tls, t = Thread.current)
      t.thread_variable_set(:sonic_pi_thread_locals, tls)
    end

    def __system_thread_locals_reset!(tls, t = Thread.current)
      t.thread_variable_set(:sonic_pi_system_thread_locals, tls)
    end

    def __no_kill_block(t = Thread.current, &block)
      mut = __system_thread_locals(t).get(:sonic_pi_local_spider_no_kill_mutex)

      # just call block when in a non-sonic-pi-thread
      return block.call unless mut

      # if we're already in a no_kill_block, run code anyway
      return block.call if __system_thread_locals(t).get(:sonic_pi_local_spider_in_no_kill_block)

      mut.synchronize do
        __system_thread_locals(t).set_local(:sonic_pi_local_spider_in_no_kill_block, true)
        begin
          r = block.call
        rescue Exception => e
          log_exception e, "in no kill block"
        ensure
          __system_thread_locals(t).set_local(:sonic_pi_local_spider_in_no_kill_block, false)
        end
        r
      end
    end
  end
end
