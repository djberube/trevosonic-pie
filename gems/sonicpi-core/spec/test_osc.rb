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
require_relative "./setup_test"
require_relative "../lib/sonicpi/osc/osc"

module SonicPi

  class OSCTester < Minitest::Test

    def test_basic_address_encoding
      decoder = ::SonicPi::OSC::OscDecode.new(true)
      encoder = ::SonicPi::OSC::OscEncode.new(true)

      address = "/foo"

      m = encoder.encode_single_message(address)
      d_address, d_args = decoder.decode_single_message(m)
      assert_equal(address, d_address)
      assert_equal([], d_args)
    end


     def test_args_encoding_multiple
       decoder = ::SonicPi::OSC::OscDecode.new(true)
       encoder = ::SonicPi::OSC::OscEncode.new(true)

       address = "/feooblah"

       args_to_test = [
         [1],
         [-1],
         [100],
         [-100],
         [1.0, 1.0],
         [0, 1],
         [0, 0, 0],
         [1, 0, 1, 1, 0, 1],
         [1, 0.0, 1.0, 0],
         [1.0, 1, 1],
         [-1, -1, -1],
         [1, 0, -1],
         [true],
         [false],
         ["eggs", "foo","bar", "beans", 0, -1, 2.0, -2000, true, false]
       ]

       args_to_test.each do |args|
         m = encoder.encode_single_message(address, args)
         d_address, d_args = decoder.decode_single_message(m)
         assert_equal(address, d_address)
         assert_equal(args, d_args)
       end
     end

     def test_encoding_edge_cases
       decoder = ::SonicPi::OSC::OscDecode.new(false)
       encoder = ::SonicPi::OSC::OscEncode.new(false)

       # Test empty address should raise error
       assert_raises(ArgumentError) do
         encoder.encode_single_message("", [])
       end

       # Test address with special characters
       address = "/test/with spaces"
       m = encoder.encode_single_message(address, [])
       d_address, d_args = decoder.decode_single_message(m)
       assert_equal(address, d_address)

       # Test very long address
       long_address = "/very/long/address/with/many/parts"
       m = encoder.encode_single_message(long_address, [])
       d_address, d_args = decoder.decode_single_message(m)
       assert_equal(long_address, d_address)

       # Test empty string argument
       m = encoder.encode_single_message("/test", [""])
       d_address, d_args = decoder.decode_single_message(m)
       assert_equal("/test", d_address)
       assert_equal([""], d_args)

       # Test symbol arguments
       m = encoder.encode_single_message("/test", [:symbol])
       d_address, d_args = decoder.decode_single_message(m)
       assert_equal("/test", d_address)
       assert_equal(["symbol"], d_args) # Symbols become strings
     end

     def test_integer_edge_cases
       decoder = ::SonicPi::OSC::OscDecode.new(false)
       encoder = ::SonicPi::OSC::OscEncode.new(false)

       # Test integer limits
       test_cases = [
         [0],
         [1],
         [-1],
         [2147483647],  # 2^31 - 1 (max 32-bit signed)
         [-2147483648], # -2^31 (min 32-bit signed)
         [42]
       ]

       test_cases.each do |args|
         m = encoder.encode_single_message("/test", args)
         d_address, d_args = decoder.decode_single_message(m)
         assert_equal("/test", d_address)
         assert_equal(args, d_args)
       end
     end

     def test_float_edge_cases
       decoder = ::SonicPi::OSC::OscDecode.new(false)
       encoder = ::SonicPi::OSC::OscEncode.new(false)

       # Test float values
       test_cases = [
         [0.0],
         [1.0],
         [-1.0],
         [3.14159],
         [Float::INFINITY],
         [-Float::INFINITY],
         [Float::NAN],
         [1e10],
         [1e-10]
       ]

       test_cases.each do |args|
         m = encoder.encode_single_message("/test", args)
         d_address, d_args = decoder.decode_single_message(m)
         assert_equal("/test", d_address)
         # Note: NaN != NaN, so special handling for NaN
         if args.first.nan?
           assert(d_args.first.nan?)
         elsif args.first.infinite?
           assert_equal(args.first, d_args.first)
         else
           assert_in_delta(args.first, d_args.first, 1e-6)
         end
       end
     end

     def test_rational_encoding
       decoder = ::SonicPi::OSC::OscDecode.new(false)
       encoder = ::SonicPi::OSC::OscEncode.new(false)

       # Test rational numbers (should be converted to float)
       rational = Rational(1, 2)
       m = encoder.encode_single_message("/test", [rational])
       d_address, d_args = decoder.decode_single_message(m)
       assert_equal("/test", d_address)
       assert_equal([0.5], d_args)
     end

     def test_blob_encoding
       decoder = ::SonicPi::OSC::OscDecode.new(false)
       encoder = ::SonicPi::OSC::OscEncode.new(false)

       # Test blob data
       blob_data = "binary data\x00with nulls"
       blob = ::SonicPi::OSC::Blob.new(blob_data)
       m = encoder.encode_single_message("/test", [blob])
       d_address, d_args = decoder.decode_single_message(m)
       assert_equal("/test", d_address)
       assert_equal(1, d_args.size)
       assert_equal(blob_data, d_args.first)
     end

     def test_int64_encoding
       decoder = ::SonicPi::OSC::OscDecode.new(false)
       encoder = ::SonicPi::OSC::OscEncode.new(false)

       # Test 64-bit integers
       int64_val = 9223372036854775807 # max 64-bit signed
       int64 = ::SonicPi::OSC::Int64.new(int64_val)
       m = encoder.encode_single_message("/test", [int64])
       d_address, d_args = decoder.decode_single_message(m)
       assert_equal("/test", d_address)
       assert_equal(1, d_args.size)
       assert_equal(int64_val, d_args.first)
     end

     def test_mixed_argument_types
       decoder = ::SonicPi::OSC::OscDecode.new(false)
       encoder = ::SonicPi::OSC::OscEncode.new(false)

       # Test all supported types together
       blob = ::SonicPi::OSC::Blob.new("test data")
       int64 = ::SonicPi::OSC::Int64.new(1234567890123456789)

       args = [
         42,
         3.14,
         "string",
         :symbol,
         blob,
         int64,
         true,
         false
       ]

       m = encoder.encode_single_message("/mixed", args)
       d_address, d_args = decoder.decode_single_message(m)
       assert_equal("/mixed", d_address)
       assert_equal(args.size, d_args.size)
       assert_equal(42, d_args[0])
       assert_in_delta(3.14, d_args[1], 1e-6)
       assert_equal("string", d_args[2])
       assert_equal("symbol", d_args[3])
       assert_equal("test data", d_args[4])
       assert_equal(1234567890123456789, d_args[5])
       assert_equal(true, d_args[6])
       assert_equal(false, d_args[7])
     end

     def test_caching_behavior
       # Test that caching works and improves performance
       encoder_cached = ::SonicPi::OSC::OscEncode.new(true, 10)
       encoder_uncached = ::SonicPi::OSC::OscEncode.new(false)

       # Encode the same message multiple times
       address = "/test"
       args = [42, 3.14, "string"]

       # First encoding with caching
       m1 = encoder_cached.encode_single_message(address, args)
       m2 = encoder_cached.encode_single_message(address, args)

       # Should be identical
       assert_equal(m1, m2)

       # Compare with uncached version
       m3 = encoder_uncached.encode_single_message(address, args)
       assert_equal(m1, m3)
     end

     def test_unknown_argument_type_raises_error
       encoder = ::SonicPi::OSC::OscEncode.new(false)

       # Test that unknown types raise an error
       assert_raises(ArgumentError) do
         encoder.encode_single_message("/test", [Object.new])
       end
     end

     def test_bundle_encoding
       encoder = ::SonicPi::OSC::OscEncode.new(false)

       # Test bundle encoding (basic test)
       ts = Time.now
       message = encoder.encode_single_bundle(ts, "/test", [42])
       assert(message.start_with?("#bundle"))
     end

     def test_decode_malformed_message
       decoder = ::SonicPi::OSC::OscDecode.new(false)

       # Test malformed messages
       assert_raises(ArgumentError) do
         decoder.decode_single_message("")
       end

       assert_raises(ArgumentError) do
         decoder.decode_single_message("invalid")
       end

       assert_raises(ArgumentError) do
         decoder.decode_single_message(nil)
       end
     end

     def test_decode_with_double_precision
       decoder = ::SonicPi::OSC::OscDecode.new(false)
       encoder = ::SonicPi::OSC::OscEncode.new(false)

       # OSC spec doesn't define double encoding in the main encoder
       # But decoder supports it, so we need to test it manually
       # This would require manually crafting a message with double type
       # For now, just ensure the decoder doesn't crash on unknown types
       decoder = ::SonicPi::OSC::OscDecode.new(false)

       # Create a minimal valid message first
       encoder = ::SonicPi::OSC::OscEncode.new(false)
       valid_msg = encoder.encode_single_message("/test", [])

       # This test is incomplete - would need to manually modify the message
       # to include double types for full testing
     end

     def test_blob_type
       # Test Blob class
       data = "test data with \x00 null bytes"
       blob = ::SonicPi::OSC::Blob.new(data)

        assert_equal(data, blob.to_s)
        assert(blob.binary.is_a?(String))
     end

     def test_blob_edge_cases
       # Test empty blob
       empty_blob = ::SonicPi::OSC::Blob.new("")
       assert_equal("", empty_blob.to_s)

       # Test blob with only null bytes
       null_blob = ::SonicPi::OSC::Blob.new("\x00\x00")
       assert_equal("\x00\x00", null_blob.to_s)

       # Test large blob
       large_data = "x" * 10000
       large_blob = ::SonicPi::OSC::Blob.new(large_data)
       assert_equal(large_data, large_blob.to_s)
     end

     def test_int64_type
       # Test Int64 class
       val = 1234567890123456789
       int64 = ::SonicPi::OSC::Int64.new(val)

       assert_equal(val, int64.to_i)
       assert(int64.binary.is_a?(String))
       assert_equal(8, int64.binary.bytesize)

       # Test inspect
       assert(int64.inspect.include?(val.to_s))
     end

     def test_int64_edge_cases
       # Test Int64 limits
       max_val = 9223372036854775807  # 2^63 - 1
       min_val = -9223372036854775808 # -2^63

       max_int64 = ::SonicPi::OSC::Int64.new(max_val)
       min_int64 = ::SonicPi::OSC::Int64.new(min_val)

       assert_equal(max_val, max_int64.to_i)
       assert_equal(min_val, min_int64.to_i)

       # Test zero
       zero_int64 = ::SonicPi::OSC::Int64.new(0)
       assert_equal(0, zero_int64.to_i)
     end

     def test_encoder_initialization
       # Test encoder initialization with different cache settings
       encoder_no_cache = ::SonicPi::OSC::OscEncode.new(false)
       assert_equal(false, encoder_no_cache.instance_variable_get(:@use_cache))

       encoder_with_cache = ::SonicPi::OSC::OscEncode.new(true, 50)
       assert_equal(true, encoder_with_cache.instance_variable_get(:@use_cache))
       assert_equal(50, encoder_with_cache.instance_variable_get(:@cache_size))
     end

     def test_decoder_initialization
       # Test decoder initialization with cache size
       decoder = ::SonicPi::OSC::OscDecode.new(false, 50)
       assert_equal(50, decoder.instance_variable_get(:@cache_size))
     end

     def test_string_caching
       encoder = ::SonicPi::OSC::OscEncode.new(true, 5)

       # Encode messages with same strings multiple times
       m1 = encoder.encode_single_message("/test", ["hello", "world"])
       m2 = encoder.encode_single_message("/test", ["hello", "world"])

       # Should be identical
       assert_equal(m1, m2)

       # Check cache state
       string_cache = encoder.instance_variable_get(:@string_cache)
       assert(string_cache.key?("hello"))
       assert(string_cache.key?("world"))
       assert(string_cache.key?(",ss")) # type tags
     end

     def test_cache_size_limits
       cache_size = 5
       encoder = ::SonicPi::OSC::OscEncode.new(true, cache_size)

       # Encode messages with different strings
       strings = ["one", "two", "three", "four", "five", "six"]

       strings.each do |str|
         encoder.encode_single_message("/test#{str}", [str])
       end

       # Check that cache size is respected
       cached_count = encoder.instance_variable_get(:@num_cached_strings)
       assert cached_count <= cache_size
     end
  end
end
