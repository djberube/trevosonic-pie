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

module SonicPi
  module OSC
    # OSC Message Encoder
    #
    # This class provides functionality to encode Ruby objects into OSC (Open Sound Control)
    # message format. It supports all standard OSC argument types including integers,
    # floats, strings, blobs, and booleans.
    #
    # Features:
    # - Caching for improved performance
    # - Input validation and error handling
    # - Support for all OSC 1.0 types
    #
    # @example Basic usage
    #   encoder = SonicPi::OSC::OscEncode.new
    #   message = encoder.encode_single_message("/play", [60, 0.5])
    #
    # @example With caching disabled
    #   encoder = SonicPi::OSC::OscEncode.new(false)
    #   message = encoder.encode_single_message("/synth", ["beep", 440.0])
    class OscEncode
      # Apologies for the density of this code - I've inlined a lot of the
      # code to reduce method dispatch overhead and to increase efficiency.
      # See https://opensoundcontrol.stanford.edu/ for spec.

      def initialize(use_cache = false, cache_size=1000)
        @literal_binary_str = "BINARY".freeze
        @literal_cap_n = 'N'.freeze
        @literal_cap_n2 = 'N2'.freeze
        @literal_low_f = 'f'.freeze
        @literal_low_i = 'i'.freeze
        @literal_low_g = 'g'.freeze
        @literal_low_s = 's'.freeze
        @literal_low_b = 'b'.freeze
        @literal_low_h = 'h'.freeze
        @literal_cap_f = 'F'.freeze
        @literal_cap_t = 'T'.freeze
        @literal_empty_str = ''.freeze
        @literal_str_encode_regexp = /\000.*\z/
        @literal_str_pad = "\000".freeze
        @literal_two_to_pow_2 = 2 ** 32
        @literal_magic_time_offset = 2208988800

        @use_cache = use_cache
        @integer_cache = {}
        @string_cache = {}
        @float_cache = {}
        @cache_size = cache_size

        @num_cached_integers = 0
        @num_cached_floats = 0
        @num_cached_strings = 0

        @bundle_header = get_from_or_add_to_string_cache("#bundle")
      end

      # Encodes a single OSC message
      #
      # @param address [String, Symbol] The OSC address pattern (must start with '/')
      # @param args [Array] Array of arguments to encode
      # @return [String] The encoded OSC message as a binary string
      # @raise [ArgumentError] If address is invalid or arguments are unsupported
      def encode_single_message(address, args=[])
        # Defensive programming: validate inputs
        raise ArgumentError, "Address must be a string or symbol" unless address.is_a?(String) || address.is_a?(Symbol)
        raise ArgumentError, "Address cannot be nil" if address.nil?
        raise ArgumentError, "Args must be an array" unless args.is_a?(Array)

        address = address.to_s
        raise ArgumentError, "Address must start with '/'" unless address.start_with?('/')

        args_encoded, tags = String.new(""), String.new(",")

        # inlining this method was not faster surprisingly
        address = get_from_or_add_to_string_cache(address)

        args.each do |arg|
          case arg
          when Integer
            # Validate integer range for 32-bit signed
            raise ArgumentError, "Integer #{arg} is outside 32-bit signed range" if arg < -2**31 || arg > 2**31 - 1
            tags << @literal_low_i

            if @use_cache
              if cached = @integer_cache[arg]
                args_encoded << cached
              else
                res = [arg].pack(@literal_cap_n)
                if @num_cached_integers < @cache_size
                  @integer_cache[arg] = res
                  @num_cached_integers += 1
                  # log "caching integer #{arg}"
                end
                args_encoded << res
              end
            else
              args_encoded << [arg].pack(@literal_cap_n)
            end
          when Float, Rational
            arg = arg.to_f
            # OSC supports infinite floats
            tags << @literal_low_f

            if @use_cache
              if cached = @float_cache[arg]
                args_encoded << cached
              else
                res = [arg].pack(@literal_low_g)
                if @num_cached_floats < @cache_size
                  @float_cache[arg] = res
                  @num_cached_floats += 1
                  # log "caching float #{arg}"
                end
                args_encoded << res
              end
            else
              args_encoded << [arg].pack(@literal_low_g)
            end
          when String, Symbol
            arg = arg.to_s
            # Validate string doesn't contain null bytes (OSC strings shouldn't)
            raise ArgumentError, "String argument cannot contain null bytes" if arg.include?("\x00")
            tags << @literal_low_s

            args_encoded << get_from_or_add_to_string_cache(arg)
          when SonicPi::OSC::Blob
            raise ArgumentError, "Blob argument cannot be nil" if arg.nil?
            tags << @literal_low_b
            args_encoded << arg.binary
          when SonicPi::OSC::Int64
            raise ArgumentError, "Int64 argument cannot be nil" if arg.nil?
            tags << @literal_low_h
            args_encoded << arg.binary
          when true
            tags << @literal_cap_t
          when false
            tags << @literal_cap_f
          else
            raise ArgumentError, "Unknown arg type to encode: #{arg.inspect} (#{arg.class})"
          end
        end

        tags_encoded = get_from_or_add_to_string_cache(tags)
        # Address here needs to be a new string, not sure why
        "#{address}#{tags_encoded}#{args_encoded}"
      end

      def encode_single_bundle(ts, address, args=[])
        raise ArgumentError, "Timestamp must be a Time or Numeric" unless ts.is_a?(Time) || ts.is_a?(Numeric)
        message = encode_single_message(address, args)
        message_encoded = [message.size].pack(@literal_cap_n) << message
        "#{@bundle_header}#{time_encoded(ts)}#{message_encoded}"
      end

      private
      def get_from_or_add_to_string_cache(s)
        if cached = @string_cache[s]
          return cached
        else
          # This makes a null padded string rounded up to the nearest
          # multiple of four
          size = s.bytesize
          res = [s].pack("Z#{size + 4 - (size % 4)}")
          if @num_cached_strings < @cache_size
            # only cache the first @cache_size strings to avoid a memory
            # memory leak.
            @string_cache[s] = res
            @num_cached_strings += 1
            # log "caching string #{s}"
          end
          return  res
        end
      end

      def time_encoded(time)
        t1, fr = (time.to_f + @literal_magic_time_offset).divmod(1)

        t2 = (fr * @literal_two_to_pow_2).to_i
        [t1, t2].pack(@literal_cap_n2)
      end
    end

    class StreamOscEncode < OscEncode
      def encode_single_message(address, args=[])
        message = super
        ([message.length].pack(@literal_cap_n) << message).force_encoding(@literal_binary_str)
      end

      def encode_single_bundle(ts, address, args=[])
        message = super
        message.count.pack(@literal_cap_n) << message
      end
    end
  end
end
