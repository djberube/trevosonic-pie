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

require_relative "buffer"
require_relative "util"
require_relative "sox"


module SonicPi
  # SampleBuffer wraps a Buffer with additional functionality for sample analysis
  # and manipulation, including onset detection, slicing, and mono conversion.
  #
  # This class provides thread-safe caching of expensive operations like onset
  # detection and audio analysis using Sox.
  #
  # @example Basic usage
  #   buffer = SampleBuffer.new(server_buffer, "/path/to/sample.wav")
  #   puts "Duration: #{buffer.duration}s"
  #   puts "Channels: #{buffer.num_chans}"
  #
  # @example Getting onset times
  #   onsets = buffer.onsets  # Returns array of onset times (0.0 to 1.0)
  #
  # @example Creating slices
  #   slices = buffer.slices(8)  # Divide into 8 equal slices
  #
  class SampleBuffer < Buffer
    include Util
    # Initialize a new SampleBuffer
    #
    # @param buffer [Buffer] The underlying buffer object from the server
    # @param path [String] Path to the sample file on disk
    # @raise [ArgumentError] If buffer or path are nil
    def initialize(buffer, path)
      # Defensive: validate inputs
      raise ArgumentError, "buffer cannot be nil" if buffer.nil?
      raise ArgumentError, "path cannot be nil" if path.nil?

      @aubio_onsets = {}
      @aubio_onset_data = nil
      @buffer = buffer
      @mono_buffer = nil
      @path = path
      @aubio_sem = Mutex.new
      @slices = {}
      @slices_sem = Mutex.new
      @sox_sem = Mutex.new
      @sox_info = nil
      @aubio_slices = nil
    end

    def num_frames
      @buffer.num_frames
    end

    def num_chans
      @buffer.num_chans
    end

    def sample_rate
      @buffer.sample_rate
    end

    def duration
      @buffer.duration
    end

    def buffer
      @buffer
    end

    def state
      @buffer.state
    end

    def path
      @path
    end

    def free
      @buffer.free
    end

    def id
      @buffer.id
    end

    def to_i
      @buffer.to_i
    end

    # Return a mono version of this sample buffer
    #
    # If the buffer is already mono (1 channel), returns self.
    # Otherwise, creates a mono mix using Sox and returns a new SampleBuffer
    # with the mono version. The result is cached for subsequent calls.
    #
    # @return [SampleBuffer] A mono version of this buffer
    # @raise [RuntimeError] If mono conversion fails
    def mono
      # Defensive: return self if already mono
      return self if num_chans == 1

      # Return cached mono buffer if it exists
      return @mono_buffer if @mono_buffer

      # Create mono version using Sox and allocate new buffer
      begin
        mono_path = Sox.mono_mix(@path)
        mono_buf_info = @buffer.server.buffer_alloc_read(mono_path)
        @mono_buffer = SampleBuffer.new(mono_buf_info, mono_path)
      rescue => e
        log_exception(e, "creating mono buffer") if respond_to?(:log_exception)
        raise RuntimeError, "Failed to create mono buffer: #{e.message}"
      end

      @mono_buffer
    end

    def info
      return @sox_info if @sox_info
      @sox_sem.synchronize do
        return @sox_info if @sox_info
        @sox_info = Sox.info(@path)
      end
      return @sox_info
    end

    # Get raw onset data from aubio analysis
    #
    # Uses the aubio_onset binary to detect onsets in the sample.
    # Results are cached for performance. Onsets are returned as
    # absolute time values in seconds.
    #
    # @return [Ring] Ring of onset times in seconds
    def onset_data
      return @aubio_onset_data if @aubio_onset_data

      @aubio_sem.synchronize do
        return @aubio_onset_data if @aubio_onset_data

        __no_kill_block do
          # These are the aubio defaults set by old gem and now
          # hard-coded into the aubio_onset binary: (this was worth
          # maintaining to preserve backwards compatibility. Might also
          # be nice to let users tweak these values in the future)

          # [:window_size]     1024
          # [:hop_size]        512
          # [:onset_threshold] 0.3
          # [:minioi_ms]       12.0 (ms)

          begin
            # Defensive: validate aubio path exists
            aubio_path = Paths.aubio_onset_path
            raise "aubio_onset binary not found at #{aubio_path}" unless File.exist?(aubio_path)

            # Defensive: validate sample file exists
            raise "Sample file not found: #{@path}" unless File.exist?(@path)

            aubio_onsets_command = "\"#{aubio_path}\" \"#{@path}\""
            onsets_str = `#{aubio_onsets_command}`

            # Defensive: check command success
            raise "aubio_onset command failed" unless $?.success?

            # Defensive: validate output
            onsets_str = onsets_str.to_s.strip
            onsets = onsets_str.empty? ? [] : onsets_str.split.map(&:to_f)

            # Defensive: validate parsed values are numeric and in range
            onsets.each do |onset|
              unless onset.is_a?(Numeric) && onset >= 0 && onset <= duration
                log "Invalid onset value: #{onset.inspect}, ignoring" if respond_to?(:log)
                onsets.delete(onset)
              end
            end

          rescue Exception => e
            log_exception e
            onsets = []
          end

          @aubio_onset_data = onsets.ring
        end
      end

      return @aubio_onset_data
    end

    # Get normalized onset times with optional stretching
    #
    # Returns onset times normalized to the range [0, 1] where 0 is the
    # start of the sample and 1 is the end. The stretch parameter allows
    # for time-stretching the onsets.
    #
    # @param stretch [Numeric] Time stretch factor (default: 1.0)
    # @return [Array<Float>] Array of normalized onset times
    # @raise [ArgumentError] If stretch is not positive
    def onsets(stretch=1)
      # Defensive: validate stretch parameter
      stretch = stretch.to_f
      raise ArgumentError, "stretch must be positive, got #{stretch}" unless stretch > 0

      return @aubio_onsets[stretch] if @aubio_onsets[stretch]

      data = onset_data

      @aubio_sem.synchronize do
        return @aubio_onsets[stretch] if @aubio_onsets[stretch]

        begin
          onset_times = data.map do |el|
            # Defensive: handle division by zero
            duration_val = duration
            raise "Invalid duration: #{duration_val}" unless duration_val > 0

            normalized = el / duration_val
            # Defensive: clamp to valid range
            clamped = [1, normalized].min
            clamped * stretch
          end

          # Defensive: sort and remove duplicates
          onset_times = onset_times.uniq.sort

          @aubio_onsets[stretch] = onset_times
        rescue => e
          log_exception(e, "calculating onset times") if respond_to?(:log_exception)
          @aubio_onsets[stretch] = []
        end
      end

      return @aubio_onsets[stretch]
    end

    # Get slices based on onset detection
    #
    # Creates slices between consecutive onsets, useful for beat-synchronized
    # sample playback. Each slice has start/finish times normalized to [0, 1]
    # and an index.
    #
    # @return [Ring<Hash>] Ring of slice hashes with :start, :finish, :index keys
    def onset_slices
      return @aubio_slices if @aubio_slices

      ons_bounds = onsets

      @aubio_sem.synchronize do
        return @aubio_slices if @aubio_slices

        begin
          res = []
          bounds = ons_bounds.dup

          # Defensive: ensure we have start and end points
          bounds.unshift(0) unless bounds.first == 0 || bounds.empty?
          bounds << 1 if bounds.last != 1

          # Defensive: sort and remove duplicates
          bounds = bounds.uniq.sort

          # Defensive: validate bounds are in [0,1] range
          bounds.each do |bound|
            unless bound.is_a?(Numeric) && bound >= 0 && bound <= 1
              raise ArgumentError, "Invalid onset bound: #{bound.inspect}"
            end
          end

          bounds.each_cons(2).each_with_index do |(start, finish), idx|
            # Defensive: ensure start < finish
            if start >= finish
              log "Skipping invalid slice: start=#{start} >= finish=#{finish}" if respond_to?(:log)
              next
            end

            res << { start: start, finish: finish, index: idx }
          end

          @aubio_slices = res.ring
        rescue => e
          log_exception(e, "creating onset slices") if respond_to?(:log_exception)
          @aubio_slices = [].ring
        end
      end

      return @aubio_slices
    end

    # Divide the sample into equal slices
    #
    # Creates a specified number of equal slices between start and finish points.
    # Useful for granular synthesis and sample manipulation.
    #
    # @param num [Integer] Number of slices to create (default: 16)
    # @param start [Float] Start position (0.0 to 1.0, default: 0.0)
    # @param finish [Float] End position (0.0 to 1.0, default: 1.0)
    # @return [Ring<Hash>] Ring of slice hashes with :start, :finish, :index keys
    # @raise [ArgumentError] If parameters are invalid
    def slices(num=16, start=0, finish=1)
      # Defensive: validate and convert parameters
      num = num.to_i
      start = start.to_f
      finish = finish.to_f

      # Defensive: validate ranges
      raise ArgumentError, "num must be positive, got #{num}" unless num > 0
      raise ArgumentError, "start must be between 0 and 1, got #{start}" unless start >= 0 && start <= 1
      raise ArgumentError, "finish must be between 0 and 1, got #{finish}" unless finish >= 0 && finish <= 1
      raise ArgumentError, "start must be less than finish, got start=#{start}, finish=#{finish}" unless start < finish

      return @slices[[num, start, finish]] if @slices[[num, start, finish]]

      res = []

      @slices_sem.synchronize do
        return @slices[[num, start, finish]] if @slices[[num, start, finish]]

        begin
          slice_size = (finish - start) / num.to_f

          # Defensive: prevent infinite loops
          max_slices = 10000
          raise ArgumentError, "Too many slices requested: #{num}" if num > max_slices

          prev = start
          num.times do |n|
            val = prev + slice_size

            # Defensive: clamp to finish
            val = finish if val > finish

            res << {:start => prev, :finish => val, index: n}
            prev = val
          end

          res = res.ring
          @slices[[num, start, finish]] = res
        rescue => e
          log_exception(e, "creating slices") if respond_to?(:log_exception)
          res = [].ring
          @slices[[num, start, finish]] = res
        end
      end

      return res
    end

    def inspect
      to_s
    end

    def to_s
      if @buffer.path
        "#<SampleBuffer @id=#{@buffer.id}, @num_chans=#{@buffer.num_chans}, @num_frames=#{@buffer.num_frames}, @sample_rate=#{@buffer.sample_rate}, @duration=#{@buffer.duration}, @path=#{@buffer.path}>"
      else
        "#<SampleBuffer @id=#{@buffer.id}, @num_chans=#{@buffer.num_chans.inspect}, @num_frames=#{@buffer.num_frames}, @sample_rate=#{@buffer.sample_rate}, @duration=#{@buffer.duration}>"
      end
    end
  end
end
