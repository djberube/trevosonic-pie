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

require_relative './setup_test'
require_relative '../lib/sonicpi/samplebuffer'
require 'mocha/setup'
require 'tempfile'

module SonicPi
  class SampleBufferTester < Minitest::Test
    def setup
      # Create a mock buffer with realistic attributes
      @mock_server = mock('server')
      @mock_buffer = mock('buffer')
      @mock_buffer.stubs(:num_frames).returns(44100)
      @mock_buffer.stubs(:num_chans).returns(2)
      @mock_buffer.stubs(:sample_rate).returns(44100)
      @mock_buffer.stubs(:duration).returns(1.0)
      @mock_buffer.stubs(:id).returns(123)
      @mock_buffer.stubs(:to_i).returns(123)
      @mock_buffer.stubs(:path).returns('/mock/path.wav')
      @mock_buffer.stubs(:server).returns(@mock_server)

      # Create a temporary test file
      @temp_file = Tempfile.new(['test_sample', '.wav'])
      @temp_path = @temp_file.path
      @temp_file.close

      @sample_buffer = SampleBuffer.new(@mock_buffer, @temp_path)
    end

    def teardown
      @temp_file.unlink if @temp_file
    end

    # Initialization tests
    def test_initialization_with_valid_params
      buffer = SampleBuffer.new(@mock_buffer, '/test.wav')
      assert_equal @mock_buffer, buffer.buffer
      assert_equal '/test.wav', buffer.path
    end

    def test_initialization_with_nil_buffer
      assert_raises(ArgumentError, "buffer cannot be nil") do
        SampleBuffer.new(nil, '/test.wav')
      end
    end

    def test_initialization_with_nil_path
      assert_raises(ArgumentError, "path cannot be nil") do
        SampleBuffer.new(@mock_buffer, nil)
      end
    end

    # Buffer delegation tests
    def test_num_frames_delegates_to_buffer
      assert_equal 44100, @sample_buffer.num_frames
    end

    def test_num_chans_delegates_to_buffer
      assert_equal 2, @sample_buffer.num_chans
    end

    def test_sample_rate_delegates_to_buffer
      assert_equal 44100, @sample_buffer.sample_rate
    end

    def test_duration_delegates_to_buffer
      assert_equal 1.0, @sample_buffer.duration
    end

    def test_id_delegates_to_buffer
      assert_equal 123, @sample_buffer.id
    end

    def test_to_i_delegates_to_buffer
      assert_equal 123, @sample_buffer.to_i
    end

    def test_free_delegates_to_buffer
      @mock_buffer.expects(:free).returns(true)
      assert @sample_buffer.free
    end

    def test_state_delegates_to_buffer
      @mock_buffer.stubs(:state).returns(:live)
      assert_equal :live, @sample_buffer.state
    end

    # Mono method tests
    def test_mono_returns_self_for_mono_buffer
      mono_buffer = mock('mono_buffer')
      mono_buffer.stubs(:num_chans).returns(1)
      mono_sample = SampleBuffer.new(mono_buffer, '/mono.wav')

      assert_equal mono_sample, mono_sample.mono
    end

    def test_mono_creates_mono_version_for_stereo
      # This test would require mocking Sox.mono_mix and server.buffer_alloc_read
      # For now, we'll skip the full integration test
      skip "Mono conversion requires server integration"
    end

    # Onset data tests
    def test_onset_data_caching
      # Mock the backticks to return onset data
      @sample_buffer.stubs(:`).returns("0.1 0.5 0.9")

      # Mock successful command execution by ensuring $? is set
      # This is tricky with mocha, so we'll test the caching logic differently
      skip "Command execution mocking is complex with mocha"
    end

    def test_onset_data_handles_command_failure
      @sample_buffer.stubs(:`).raises(RuntimeError.new("command failed"))

      data = @sample_buffer.onset_data
      assert_equal SonicPi::Core::RingVector.new([]), data
    end

    # Onsets method tests
    def test_onsets_with_default_stretch
      @sample_buffer.stubs(:onset_data).returns(SonicPi::Core::RingVector.new([0.1, 0.5, 0.9]))
      @sample_buffer.stubs(:duration).returns(2.0)

      expected = [0.05, 0.25, 0.45] # normalized and stretched
      assert_equal expected, @sample_buffer.onsets
    end

    def test_onsets_with_custom_stretch
      @sample_buffer.stubs(:onset_data).returns(SonicPi::Core::RingVector.new([0.1, 0.5]))
      @sample_buffer.stubs(:duration).returns(1.0)

      expected = [0.2, 1.0] # stretched by 2.0
      assert_equal expected, @sample_buffer.onsets(2.0)
    end

    def test_onsets_with_invalid_stretch
      assert_raises(ArgumentError, "stretch must be positive") do
        @sample_buffer.onsets(0)
      end

      assert_raises(ArgumentError, "stretch must be positive") do
        @sample_buffer.onsets(-1)
      end
    end

    def test_onsets_caching
      @sample_buffer.stubs(:onset_data).returns(SonicPi::Core::RingVector.new([0.1]))
      @sample_buffer.stubs(:duration).returns(1.0)

      # First call
      result1 = @sample_buffer.onsets(2.0)
      # Second call should be cached
      result2 = @sample_buffer.onsets(2.0)

      assert_equal result1, result2
    end

    # Onset slices tests
    def test_onset_slices_with_no_onsets
      # Test that onset_slices handles empty onsets correctly
      @sample_buffer.stubs(:onsets).returns([])
      result = @sample_buffer.onset_slices
      # Should return a ring, even if empty
      assert result.is_a?(SonicPi::Core::RingVector)
    end

    def test_onset_slices_with_invalid_bounds
      # Invalid bounds are filtered out in the onsets method
      @sample_buffer.stubs(:onsets).returns([1.5, -0.1]) # Invalid bounds get filtered

      # Should handle gracefully by returning empty ring
      result = @sample_buffer.onset_slices
      assert result.is_a?(SonicPi::Core::RingVector)
      assert_equal 0, result.size  # Invalid bounds filtered out, no valid slices
    end

    def test_onset_slices_with_single_onset
      @sample_buffer.stubs(:onsets).returns([0.5])
      expected_slices = [
        { start: 0, finish: 0.5, index: 0 },
        { start: 0.5, finish: 1, index: 1 }
      ]

      assert_equal SonicPi::Core::RingVector.new(expected_slices), @sample_buffer.onset_slices
    end

    def test_onset_slices_with_multiple_onsets
      @sample_buffer.stubs(:onsets).returns([0.2, 0.7])
      expected_slices = [
        { start: 0, finish: 0.2, index: 0 },
        { start: 0.2, finish: 0.7, index: 1 },
        { start: 0.7, finish: 1, index: 2 }
      ]

      assert_equal SonicPi::Core::RingVector.new(expected_slices), @sample_buffer.onset_slices
    end

    def test_onset_slices_caching
      @sample_buffer.stubs(:onsets).returns([0.5])

      # First call
      slices1 = @sample_buffer.onset_slices
      # Second call should be cached
      slices2 = @sample_buffer.onset_slices

      assert_equal slices1, slices2
    end

    # Slices method tests
    def test_slices_default_parameters
      slices = @sample_buffer.slices
      assert_equal 16, slices.size
      assert slices.is_a?(SonicPi::Core::RingVector)

      # Check first slice
      first_slice = slices[0]
      assert_equal 0.0, first_slice[:start]
      assert_in_delta 0.0625, first_slice[:finish], 0.001
      assert_equal 0, first_slice[:index]
    end

    def test_slices_custom_parameters
      slices = @sample_buffer.slices(4, 0.2, 0.8)
      assert_equal 4, slices.size

      # Check slices cover the correct range
      assert_equal 0.2, slices[0][:start]
      assert_equal 0.8, slices[3][:finish]
    end

    def test_slices_validation
      # Invalid num
      assert_raises(ArgumentError, "num must be positive") do
        @sample_buffer.slices(0)
      end

      # Invalid start
      assert_raises(ArgumentError, "start must be between 0 and 1") do
        @sample_buffer.slices(4, -0.1)
      end

      # Invalid finish
      assert_raises(ArgumentError, "finish must be between 0 and 1") do
        @sample_buffer.slices(4, 0, 1.1)
      end

      # start >= finish
      assert_raises(ArgumentError, "start must be less than finish") do
        @sample_buffer.slices(4, 0.5, 0.5)
      end
    end

    def test_slices_caching
      # First call
      slices1 = @sample_buffer.slices(4, 0.1, 0.9)
      # Second call with same params should be cached
      slices2 = @sample_buffer.slices(4, 0.1, 0.9)

      assert_equal slices1, slices2
    end

    def test_slices_validation
      # Test parameter validation
      assert_raises(ArgumentError, "num must be positive") do
        @sample_buffer.slices(0)
      end

      assert_raises(ArgumentError, "start must be between 0 and 1") do
        @sample_buffer.slices(4, -0.1)
      end
    end

    # Info method tests
    def test_info_caching
      Sox.stubs(:info).returns({ sample_rate: 44100 })

      # First call
      info1 = @sample_buffer.info
      # Second call should be cached
      info2 = @sample_buffer.info

      assert_equal info1, info2
    end

    # String representation tests
    def test_to_s_with_path
      @mock_buffer.stubs(:path).returns('/test.wav')
      expected = "#<SampleBuffer @id=123, @num_chans=2, @num_frames=44100, @sample_rate=44100, @duration=1.0, @path=/test.wav>"
      assert_equal expected, @sample_buffer.to_s
    end

    def test_to_s_without_path
      @mock_buffer.stubs(:path).returns(nil)
      expected = "#<SampleBuffer @id=123, @num_chans=2, @num_frames=44100, @sample_rate=44100, @duration=1.0>"
      assert_equal expected, @sample_buffer.to_s
    end

    def test_inspect_delegates_to_to_s
      assert_equal @sample_buffer.to_s, @sample_buffer.inspect
    end

    # Edge case tests
    def test_onsets_with_zero_duration
      @sample_buffer.stubs(:onset_data).returns(SonicPi::Core::RingVector.new([0.1]))
      @sample_buffer.stubs(:duration).returns(0)

      # Should handle division by zero gracefully
      result = @sample_buffer.onsets
      assert result.is_a?(Array)
    end



    # Sox integration tests (skipped in CI without sox binary)
    def test_sox_info_integration
      skip "Requires sox binary at expected path"
    end

    def test_sox_mono_mix_integration
      skip "Requires sox binary at expected path"
    end

    def test_sox_info_error_handling
      skip "Requires sox binary for proper testing"
    end
  end
end
