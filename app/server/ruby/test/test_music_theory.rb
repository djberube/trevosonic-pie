#!/usr/bin/env ruby
#--
# This file is part of Trevosonic Pie
# Based on Sonic Pi: http://sonic-pi.net
# License: https://github.com/samaaron/sonic-pi/blob/main/LICENSE.md
#
# Copyright 2013-2025 Sam Aaron (http://sam.aaron.name).
# Trevosonic Pie additions Copyright 2025 David Berube.
# All rights reserved.
#
# Permission is granted for use, copying, modification, and
# distribution of modified versions of this work as long as this
# notice is included.
#++

require_relative "setup_test"
require_relative "../lib/sonicpi/music_theory"
require_relative "../lib/sonicpi/note"

module SonicPi
  class MusicTheoryTester < Minitest::Test
    def test_interval_calculation
      # Test basic intervals
      assert_equal 0, MusicTheory.interval(:c4, :c4)
      assert_equal 4, MusicTheory.interval(:c4, :e4)
      assert_equal 7, MusicTheory.interval(:c4, :g4)
      assert_equal 12, MusicTheory.interval(:c4, :c5)

      # Test with MIDI numbers
      assert_equal 4, MusicTheory.interval(60, 64)
      assert_equal 7, MusicTheory.interval(60, 67)
    end

    def test_interval_name
      assert_equal 'Unison', MusicTheory.interval_name(0)
      assert_equal 'Minor 2nd', MusicTheory.interval_name(1)
      assert_equal 'Major 3rd', MusicTheory.interval_name(4)
      assert_equal 'Perfect 5th', MusicTheory.interval_name(7)
      assert_equal 'Octave', MusicTheory.interval_name(12)
    end

    def test_resolve_interval
      assert_equal 4, MusicTheory.resolve_interval(:major_third)
      assert_equal 4, MusicTheory.resolve_interval(:M3)
      assert_equal 7, MusicTheory.resolve_interval(:perfect_fifth)
      assert_equal 7, MusicTheory.resolve_interval(:P5)
      assert_equal 5, MusicTheory.resolve_interval(5)
    end

    def test_transpose_up
      assert_equal 64, MusicTheory.transpose(:c4, :major_third)
      assert_equal 67, MusicTheory.transpose(:c4, :perfect_fifth)
      assert_equal 72, MusicTheory.transpose(:c4, :octave)
    end

    def test_transpose_down
      assert_equal 56, MusicTheory.transpose(:c4, :major_third, :down)
      assert_equal 53, MusicTheory.transpose(:c4, :perfect_fifth, :down)
      assert_equal 48, MusicTheory.transpose(:c4, :octave, :down)
    end

    def test_voice_leading
      chord = [60, 64, 67]
      result = MusicTheory.voice_leading(chord, 72)
      assert_equal [67, 64, 60], result
    end

    def test_invert_chord
      chord = [60, 64, 67]

      # Root position
      assert_equal [60, 64, 67], MusicTheory.invert_chord(chord, 0)

      # First inversion
      assert_equal [64, 67, 72], MusicTheory.invert_chord(chord, 1)

      # Second inversion
      assert_equal [67, 72, 76], MusicTheory.invert_chord(chord, 2)
    end

    def test_drop_voicing
      chord = [60, 64, 67, 71]

      # Drop-2
      result = MusicTheory.drop_voicing(chord, 2)
      assert_equal [55, 60, 64, 71], result
    end

    def test_circle_of_fifths
      progression = MusicTheory.circle_of_fifths(:c4, 4)
      assert_equal 5, progression.length
      assert_equal 60, progression[0]
      assert_equal 67, progression[1]  # G
    end

    def test_common_tones
      chord1 = [60, 64, 67]  # C E G
      chord2 = [65, 69, 72]  # F A C

      common = MusicTheory.common_tones(chord1, chord2)
      assert_equal [0], common  # C is common
    end

    def test_harmonic_distance
      chord1 = [60, 64, 67]
      chord2 = [62, 65, 69]

      distance = MusicTheory.harmonic_distance(chord1, chord2)
      assert distance > 0
    end

    def test_scale_from_intervals
      major_intervals = [2, 2, 1, 2, 2, 2, 1]
      scale = MusicTheory.scale_from_intervals(:c4, major_intervals)

      assert_equal 8, scale.length
      assert_equal 60, scale[0]  # C
      assert_equal 62, scale[1]  # D
      assert_equal 64, scale[2]  # E
    end

    def test_in_scale
      c_major = [60, 62, 64, 65, 67, 69, 71]

      assert MusicTheory.in_scale?(:c4, c_major)
      assert MusicTheory.in_scale?(:e4, c_major)
      refute MusicTheory.in_scale?(:cs4, c_major)
    end

    def test_quantize_to_scale
      c_major = [60, 62, 64, 65, 67, 69, 71]

      # 61 is between C and D, should snap to one of them
      result = MusicTheory.quantize_to_scale(61, c_major)
      assert [60, 62].include?(result)

      # 60 should stay 60
      assert_equal 60, MusicTheory.quantize_to_scale(60, c_major)
    end

    # Test error handling
    def test_invalid_interval_raises_error
      assert_raises(MusicTheory::InvalidIntervalError) do
        MusicTheory.resolve_interval(:invalid_interval)
      end
    end

    def test_nil_note_raises_error
      assert_raises(ArgumentError) do
        MusicTheory.interval(nil, :c4)
      end
    end

    def test_empty_chord_raises_error
      assert_raises(ArgumentError) do
        MusicTheory.voice_leading([], 60)
      end
    end
  end
end
