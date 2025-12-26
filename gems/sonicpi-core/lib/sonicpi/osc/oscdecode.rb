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
    # OSC Message Decoder
    #
    # This class provides functionality to decode OSC (Open Sound Control) messages
    # from binary format back into Ruby objects. It supports all standard OSC
    # argument types and includes robust error handling and validation.
    #
    # Features:
    # - Caching for improved performance
    # - Comprehensive input validation
    # - Support for all OSC 1.0 types
    # - Detailed error messages for malformed messages
    #
    # @example Basic usage
    #   decoder = SonicPi::OSC::OscDecode.new
    #   address, args = decoder.decode_single_message(message)
    class OscDecode

      def initialize(use_cache = false, cache_size=1000)
        @float_cache = {}
        @integer_cache = {}
        @cache_size = cache_size

        @num_cached_integers = 0
        @num_cached_floats = 0
        @string_terminator = "\x00".freeze
        @args = []
        @i_tag = "i".freeze
        @f_tag = "f".freeze
        @s_tag = "s".freeze
        @d_tag = "d".freeze
        @h_tag = "h".freeze
        @b_tag = "b".freeze
        @ut_tag = "T".freeze
        @uf_tag = "F".freeze

        @cap_n = 'N'.freeze
        @cap_g = 'G'.freeze
        @low_g = 'g'.freeze
        @q_lt = 'q>'.freeze
        @binary_encoding = "BINARY".freeze
      end

      # Decodes a single OSC message from binary format
      #
      # @param m [String] The binary OSC message to decode
      # @return [Array] A two-element array: [address, args]
      # @raise [ArgumentError] If the message is malformed or invalid
      def decode_single_message(m)
        ## Note everything is inlined here for effienciency to remove the
        ## cost of method dispatch. Apologies if this makes it harder to
        ## read & understand. See https://opensoundcontrol.stanford.edu/ for spec.

        raise ArgumentError, "Message cannot be nil" if m.nil?
        raise ArgumentError, "Message must be a string" unless m.is_a?(String)
        raise ArgumentError, "Message cannot be empty" if m.empty?

        m.force_encoding(@binary_encoding)

        args, idx = [], 0

        # Get OSC address e.g. /foo
        orig_idx = idx
        terminator_idx = m.index(@string_terminator, orig_idx)
        raise ArgumentError, "Invalid OSC message: no null terminator found for address" if terminator_idx.nil?
        raise ArgumentError, "Invalid OSC message: address terminator at invalid position" if terminator_idx < orig_idx

        address = m[orig_idx...terminator_idx]
        raise ArgumentError, "Invalid OSC message: address cannot be empty" if address.empty?
        raise ArgumentError, "Invalid OSC message: address must start with '/'" unless address.start_with?('/')

        # Calculate padding to next 4-byte boundary
        padding = 1 + ((4 - ((terminator_idx + 1) % 4)) % 4)
        idx = terminator_idx + padding

        # If we've reached the end of the message, there are no arguments
        if idx >= m.bytesize
          return address, []
        end

        raise ArgumentError, "Invalid OSC message: message too short for separator" if idx >= m.bytesize
        sep = m[idx]
        idx += 1

        # Let's see if we have some args..
        if sep == ?,

          # Get type tags - the type tags string starts with the sep
          orig_idx = idx - 1
          terminator_idx = m.index(@string_terminator, orig_idx)
          raise ArgumentError, "Invalid OSC message: no null terminator found for type tags" if terminator_idx.nil?
          raise ArgumentError, "Invalid OSC message: type tags terminator at invalid position" if terminator_idx < orig_idx

          tags = m[orig_idx...terminator_idx]
          raise ArgumentError, "Invalid OSC message: type tags must start with ','" unless tags.start_with?(',')
          # For no arguments, tags should be just ","
          type_tags = tags[1..-1] # Remove the leading ','

          # Calculate padding to next 4-byte boundary
          padding = 1 + ((4 - ((terminator_idx + 1) % 4)) % 4)
          idx = terminator_idx + padding

          raise ArgumentError, "Invalid OSC message: message too short for type tags" if idx > m.bytesize

          type_tags.each_char do |t|
            raise ArgumentError, "Invalid OSC message: insufficient data for argument type #{t}" if idx + type_size(t) > m.bytesize

            case t
            when @i_tag
              # int32
              raw = m[idx, 4]
              arg, idx = @integer_cache[raw], idx + 4

              unless arg
                arg = raw.unpack(@cap_n)[0]
                # Values placed inline for efficiency:
                # 2**32 == 4294967296
                # 2**31 - 1 == 2147483647
                arg -= 4294967296 if arg > 2147483647
                if @num_cached_integers < @cache_size
                  @integer_cache[raw] = arg
                  @num_cached_integers += 1
                end
              end
            when @f_tag
              # float32
              raw = m[idx, 4]
              arg, idx = @float_cache[raw], idx + 4
              unless arg
                arg = raw.unpack(@low_g)[0]
                if @num_cached_floats < @cache_size
                  @float_cache[raw] = arg
                  @num_cached_floats += 1
                end
              end
            when @s_tag
              # string
              orig_idx = idx
              terminator_idx = m.index(@string_terminator, orig_idx)
              raise ArgumentError, "Invalid OSC message: no null terminator found for string argument" if terminator_idx.nil?
              arg = m[orig_idx...terminator_idx]
              # Calculate padding to next 4-byte boundary
              padding = 1 + ((4 - ((terminator_idx + 1) % 4)) % 4)
              idx = terminator_idx + padding
            when @d_tag
              # double64
              arg, idx = m[idx, 8].unpack(@cap_g)[0], idx + 8
            when @h_tag
              # int64
              arg, idx = m[idx, 8].unpack(@q_lt)[0], idx + 8
            when @b_tag
              # binary blob
              l = m[idx, 4].unpack(@cap_n)[0]
              raise ArgumentError, "Invalid OSC message: blob size #{l} is negative or unreasonably large" if l < 0 || l > 1_000_000
              idx += 4
              raise ArgumentError, "Invalid OSC message: insufficient data for blob of size #{l}" if idx + l > m.bytesize
              arg = m[idx, l]
              idx += l
              # Skip padding
              padding = ((4 - (idx % 4)) % 4)
              idx += padding
            when @ut_tag
              # true
              arg = true
            when @uf_tag
              # false
              arg = false
            else
              raise ArgumentError, "Unknown OSC type tag '#{t}' (#{t.ord})"
            end

            args << arg
          end
        end
        return address, args
      end

      private

      def type_size(type_tag)
        case type_tag
        when @i_tag, @f_tag
          4
        when @d_tag, @h_tag
          8
        when @s_tag
          # Variable size - can't determine statically
          0
        when @b_tag
          # Variable size - can't determine statically
          0
        when @ut_tag, @uf_tag
          0 # No additional data
        else
          0
        end
      end

    end
  end
end
