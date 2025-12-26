#--
# This file is part of Trevosonic Pie
# Based on Sonic Pi: http://sonic-pi.net
# Trevosonic Pie: https://github.com/davidjberube/trevosonic-pie
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

require_relative "./setup_test"
require_relative "../lib/sonicpi/pattern"

module SonicPi
  class PatternTester < Minitest::Test

    # Basic pattern parsing tests
    def test_simple_sequence
      pattern = Pattern.new("c e g b")
      assert_equal 4, pattern.events.length
      assert_equal "c", pattern.events[0].value
      assert_equal "e", pattern.events[1].value
      assert_equal "g", pattern.events[2].value
      assert_equal "b", pattern.events[3].value
    end

    def test_pattern_with_rests
      pattern = Pattern.new("c ~ g ~")
      assert_equal 4, pattern.events.length
      assert_equal "c", pattern.events[0].value
      assert pattern.events[1].rest?
      assert_equal "g", pattern.events[2].value
      assert pattern.events[3].rest?
    end

    def test_polyphonic_chord
      pattern = Pattern.new("[c,e,g]")
      assert_equal 1, pattern.events.length
      assert pattern.events[0].chord?
      assert_equal ["c", "e", "g"], pattern.events[0].value
    end

    def test_subdivision
      pattern = Pattern.new("c [e g] b")
      assert_equal 4, pattern.events.length

      # First event should take 1/3 of cycle
      assert_in_delta 0.0, pattern.events[0].start, 0.001
      assert_in_delta 1.0/3, pattern.events[0].duration, 0.001

      # Second and third events are subdivisions, each taking 1/6
      assert_in_delta 1.0/3, pattern.events[1].start, 0.001
      assert_in_delta 1.0/6, pattern.events[1].duration, 0.001

      assert_in_delta 1.0/2, pattern.events[2].start, 0.001
      assert_in_delta 1.0/6, pattern.events[2].duration, 0.001

      # Last event takes 1/3
      assert_in_delta 2.0/3, pattern.events[3].start, 0.001
      assert_in_delta 1.0/3, pattern.events[3].duration, 0.001
    end

    def test_nested_subdivisions
      pattern = Pattern.new("c [e [g a]]")
      assert_equal 4, pattern.events.length
    end

    # Pattern duration tests
    def test_default_duration
      pattern = Pattern.new("c e g b")
      assert_equal 1.0, pattern.duration
    end

    def test_custom_duration
      pattern = Pattern.new("c e g b", duration: 2.0)
      assert_equal 2.0, pattern.duration
      assert_equal 0.5, pattern.events[0].duration
    end

    # Pattern transformation tests
    def test_reverse
      pattern = Pattern.new("c e g b")
      reversed = pattern.rev

      assert_equal 4, reversed.events.length
      assert_equal "b", reversed.events[0].value
      assert_equal "g", reversed.events[1].value
      assert_equal "e", reversed.events[2].value
      assert_equal "c", reversed.events[3].value
    end

    def test_slow
      pattern = Pattern.new("c e g b")
      slowed = pattern.slow(2)

      assert_equal 2.0, slowed.duration
      assert_equal 4, slowed.events.length
    end

    def test_fast
      pattern = Pattern.new("c e g b")
      faster = pattern.fast(2)

      assert_equal 0.5, faster.duration
      assert_equal 4, faster.events.length
    end

    def test_rotate
      pattern = Pattern.new("c e g b")
      rotated = pattern.rotate(1)

      assert_equal 4, rotated.events.length
      assert_equal "e", rotated.events[0].value
      assert_equal "g", rotated.events[1].value
      assert_equal "b", rotated.events[2].value
      assert_equal "c", rotated.events[3].value
    end

    def test_rotate_wraps
      pattern = Pattern.new("c e g b")
      rotated = pattern.rotate(5) # Should wrap around

      assert_equal "e", rotated.events[0].value
    end

    # Event tests
    def test_event_offset
      event = Pattern::Event.new("c", 0.0, 0.25, :note)
      offset = event.offset_by(1.0)

      assert_equal 1.0, offset.start
      assert_equal 0.25, offset.duration
      assert_equal "c", offset.value
    end

    def test_events_for_cycle
      pattern = Pattern.new("c e g b")
      cycle_0 = pattern.events_for_cycle(0)
      cycle_1 = pattern.events_for_cycle(1)

      assert_equal 4, cycle_0.length
      assert_equal 4, cycle_1.length

      assert_equal 0.0, cycle_0[0].start
      assert_equal 1.0, cycle_1[0].start
    end

    # Immutability tests
    def test_pattern_immutability
      pattern = Pattern.new("c e g b")
      assert pattern.frozen?
      assert pattern.events.frozen?
      pattern.events.each do |event|
        assert event.frozen?
      end
    end

    def test_transformation_creates_new_pattern
      pattern = Pattern.new("c e g b")
      reversed = pattern.rev

      refute_equal pattern.object_id, reversed.object_id
      assert_equal "c", pattern.events[0].value
      assert_equal "b", reversed.events[0].value
    end

    # Edge cases
    def test_empty_pattern
      pattern = Pattern.new("")
      assert_equal 0, pattern.events.length
    end

    def test_pattern_with_only_rests
      pattern = Pattern.new("~ ~ ~ ~")
      assert_equal 4, pattern.events.length
      pattern.events.each do |event|
        assert event.rest?
      end
    end

    def test_complex_chord_sequence
      pattern = Pattern.new("[c,e,g] [d,f,a]")
      assert_equal 2, pattern.events.length
      assert pattern.events[0].chord?
      assert pattern.events[1].chord?
    end

    # String representation tests
    def test_pattern_to_s
      pattern = Pattern.new("c e g b")
      assert_includes pattern.to_s, "Pattern"
      assert_includes pattern.to_s, "c e g b"
    end

    def test_event_to_s
      event = Pattern::Event.new("c", 0.0, 0.25, :note)
      assert_equal "c", event.to_s

      rest = Pattern::Event.new(nil, 0.0, 0.25, :rest)
      assert_equal "~", rest.to_s

      chord = Pattern::Event.new(["c", "e", "g"], 0.0, 0.25, :chord)
      assert_equal "[c,e,g]", chord.to_s
    end
  end
end
