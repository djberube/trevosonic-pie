#--
# This file is part of Sonic Pi: http://sonic-pi.net
# Full project source: https://github.com/samaaron/sonic-pi
# License: https://github.com/samaaron/sonic-pi/blob/main/LICENSE.md
#
# Copyright 2020 by Sam Aaron (http://sam.aaron.name).
# All rights reserved.
#
# Permission is granted for use, copying, modification, and
# distribution of modified versions of this work as long as this
# notice is included.
#++


module SonicPi
  module OSC
    # OSC Blob Type
    #
    # Represents binary data in OSC messages. OSC blobs are length-prefixed
    # binary data with padding to 4-byte boundaries.
    #
    # @example Creating a blob
    #   data = "binary data"
    #   blob = SonicPi::OSC::Blob.new(data)
    #   # Use blob.binary in OSC encoding
    class Blob

      attr_reader :binary, :data

      # Creates a new OSC blob
      #
      # @param data [String] The binary data to encapsulate
      # @raise [ArgumentError] If data is invalid or too large
      def initialize(data)
        raise ArgumentError, "Blob data cannot be nil" if data.nil?
        raise ArgumentError, "Blob data must be a string" unless data.is_a?(String)

        @data = data
        size = data.bytesize
        raise ArgumentError, "Blob data is too large (max 1MB)" if size > 1_000_000

        b = ([size].pack('N') + data).force_encoding("BINARY")
        # add padding
        padding_size = (4 - (b.size % 4)) % 4
        @binary = b + ("\000" * padding_size)
      end

      def to_s
        @data
      end

      def inspect
        @binary.inspect
      end

    end

    # OSC 64-bit Integer Type
    #
    # Represents 64-bit integers in OSC messages. OSC doesn't have a standard
    # 64-bit integer type, but this class provides it for extended functionality.
    #
    # @example Creating a 64-bit integer
    #   int64 = SonicPi::OSC::Int64.new(1234567890123456789)
    #   # Use int64.binary in OSC encoding
    class Int64
      attr_reader :binary

      # Creates a new 64-bit integer
      #
      # @param val [Integer] The integer value
      # @raise [ArgumentError] If value is outside 64-bit range
      def initialize(val)
        raise ArgumentError, "Int64 value cannot be nil" if val.nil?
        raise ArgumentError, "Int64 value must be an integer" unless val.is_a?(Integer)

        # Validate 64-bit signed range
        raise ArgumentError, "Int64 value #{val} is outside 64-bit signed range" if val < -2**63 || val > 2**63 - 1

        @val = val
        @binary = [val].pack('q>')
      end

      def to_i
        @val.to_i
      end

      def inspect
        @val.inspect
      end
    end
  end
end
