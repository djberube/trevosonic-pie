#!/usr/bin/env ruby
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

require_relative 'note'
require_relative 'scale'
require_relative 'chord'

module SonicPi
  # Music theory utilities for advanced musical operations
  #
  # Provides helper functions for interval analysis, voice leading,
  # harmonic analysis, and other music theory operations.
  module MusicTheory
    # Error classes
    class InvalidIntervalError < ArgumentError; end
    class InvalidVoicingError < ArgumentError; end

    # Interval names and semitone distances
    INTERVALS = {
      unison: 0,
      perfect_unison: 0,
      minor_second: 1,
      m2: 1,
      semitone: 1,
      half_step: 1,
      major_second: 2,
      M2: 2,
      tone: 2,
      whole_step: 2,
      minor_third: 3,
      m3: 3,
      major_third: 4,
      M3: 4,
      perfect_fourth: 5,
      P4: 5,
      fourth: 5,
      augmented_fourth: 6,
      tritone: 6,
      diminished_fifth: 6,
      perfect_fifth: 7,
      P5: 7,
      fifth: 7,
      minor_sixth: 8,
      m6: 8,
      major_sixth: 9,
      M6: 9,
      minor_seventh: 10,
      m7: 10,
      major_seventh: 11,
      M7: 11,
      octave: 12,
      perfect_octave: 12
    }.freeze

    # Interval quality names
    INTERVAL_NAMES = {
      0 => 'Unison',
      1 => 'Minor 2nd',
      2 => 'Major 2nd',
      3 => 'Minor 3rd',
      4 => 'Major 3rd',
      5 => 'Perfect 4th',
      6 => 'Tritone',
      7 => 'Perfect 5th',
      8 => 'Minor 6th',
      9 => 'Major 6th',
      10 => 'Minor 7th',
      11 => 'Major 7th',
      12 => 'Octave'
    }.freeze

    module_function

    # Calculate interval between two notes
    #
    # @param note1 [Object] First note (MIDI number or note name)
    # @param note2 [Object] Second note (MIDI number or note name)
    # @return [Integer] Interval in semitones
    # @raise [ArgumentError] if notes are invalid
    #
    # @example
    #   MusicTheory.interval(:c4, :e4) #=> 4
    #   MusicTheory.interval(60, 64) #=> 4
    def interval(note1, note2)
      midi1 = Note.resolve_midi_note(note1)
      midi2 = Note.resolve_midi_note(note2)

      raise ArgumentError, "Invalid note: #{note1.inspect}" if midi1.nil?
      raise ArgumentError, "Invalid note: #{note2.inspect}" if midi2.nil?

      (midi2 - midi1).abs
    end

    # Get interval name
    #
    # @param semitones [Integer] Number of semitones
    # @return [String] Interval name
    #
    # @example
    #   MusicTheory.interval_name(4) #=> "Major 3rd"
    def interval_name(semitones)
      raise InvalidIntervalError, "Semitones must be numeric" unless semitones.is_a?(Numeric)

      semitones_int = semitones.to_i.abs

      # Handle octaves and larger intervals
      octaves = semitones_int / 12
      remainder = semitones_int % 12

      base_name = INTERVAL_NAMES[remainder] || "Unknown"

      if octaves > 0 && remainder == 0
        "Octave" + (octaves > 1 ? " (#{octaves} octaves)" : "")
      elsif octaves > 0
        "#{base_name} + #{octaves} octave(s)"
      else
        base_name
      end
    end

    # Resolve interval from name or semitones
    #
    # @param interval [Symbol, String, Numeric] Interval name or semitones
    # @return [Integer] Number of semitones
    # @raise [InvalidIntervalError] if interval is invalid
    #
    # @example
    #   MusicTheory.resolve_interval(:major_third) #=> 4
    #   MusicTheory.resolve_interval(4) #=> 4
    def resolve_interval(interval)
      return interval.to_i if interval.is_a?(Numeric)

      # Normalize to symbol
      interval_sym = interval.to_sym rescue nil

      # Try direct lookup first
      semitones = INTERVALS[interval_sym]
      return semitones if semitones

      # Try with underscore conversion
      interval_sym = interval.to_s.downcase.gsub(/[^a-z0-9]/, '_').to_sym
      semitones = INTERVALS[interval_sym]

      raise InvalidIntervalError, "Unknown interval: #{interval.inspect}" if semitones.nil?

      semitones
    end

    # Transpose a note by an interval
    #
    # @param note [Object] Note to transpose
    # @param interval [Object] Interval (name or semitones)
    # @param direction [Symbol] :up or :down (default: :up)
    # @return [Integer] Transposed MIDI note
    #
    # @example
    #   MusicTheory.transpose(:c4, :major_third) #=> 64
    #   MusicTheory.transpose(:c4, 5, :down) #=> 55
    def transpose(note, interval, direction = :up)
      midi_note = Note.resolve_midi_note(note)
      semitones = resolve_interval(interval)

      raise ArgumentError, "Invalid note: #{note.inspect}" if midi_note.nil?
      raise ArgumentError, "Direction must be :up or :down" unless [:up, :down].include?(direction)

      if direction == :up
        midi_note + semitones
      else
        midi_note - semitones
      end
    end

    # Find closest voicing of a chord to a target note
    #
    # @param chord_notes [Array<Integer>] MIDI notes of chord
    # @param target_note [Integer] Target MIDI note
    # @return [Array<Integer>] Chord notes reordered by proximity to target
    #
    # @example
    #   MusicTheory.voice_leading([60, 64, 67], 72)
    def voice_leading(chord_notes, target_note)
      raise ArgumentError, "Chord notes must be an array" unless chord_notes.is_a?(Array)
      raise ArgumentError, "Target note must be numeric" unless target_note.is_a?(Numeric)
      raise ArgumentError, "Chord notes cannot be empty" if chord_notes.empty?

      target_midi = target_note.to_i
      chord_notes.sort_by { |note| (note - target_midi).abs }
    end

    # Invert a chord
    #
    # @param chord_notes [Array<Integer>] MIDI notes of chord
    # @param inversion [Integer] Inversion number (0 = root position, 1 = first inversion, etc.)
    # @return [Array<Integer>] Inverted chord notes
    #
    # @example
    #   MusicTheory.invert_chord([60, 64, 67], 1) #=> [64, 67, 72]
    def invert_chord(chord_notes, inversion = 1)
      raise ArgumentError, "Chord notes must be an array" unless chord_notes.is_a?(Array)
      raise ArgumentError, "Inversion must be numeric" unless inversion.is_a?(Numeric)
      raise ArgumentError, "Chord notes cannot be empty" if chord_notes.empty?

      inversion_int = inversion.to_i % chord_notes.length
      return chord_notes.dup if inversion_int == 0

      notes = chord_notes.sort.dup
      inversion_int.times do
        bottom_note = notes.shift
        notes.push(bottom_note + 12)
      end

      notes
    end

    # Drop voicing (drop second highest note by an octave)
    #
    # @param chord_notes [Array<Integer>] MIDI notes of chord
    # @param drop [Integer] Which note to drop (2 = drop-2, 3 = drop-3, etc.)
    # @return [Array<Integer>] Dropped chord voicing
    #
    # @example
    #   MusicTheory.drop_voicing([60, 64, 67, 71], 2) #=> [60, 55, 64, 71]
    def drop_voicing(chord_notes, drop = 2)
      raise ArgumentError, "Chord notes must be an array" unless chord_notes.is_a?(Array)
      raise ArgumentError, "Drop value must be numeric" unless drop.is_a?(Numeric)
      raise ArgumentError, "Chord must have at least #{drop} notes" if chord_notes.length < drop

      drop_int = drop.to_i
      raise ArgumentError, "Drop value must be at least 2" if drop_int < 2

      notes = chord_notes.sort.dup
      drop_index = notes.length - drop_int

      notes[drop_index] -= 12
      notes.sort
    end

    # Calculate the circle of fifths progression
    #
    # @param root [Object] Root note
    # @param steps [Integer] Number of steps around the circle (positive = fifths, negative = fourths)
    # @return [Array<Integer>] MIDI notes of the progression
    #
    # @example
    #   MusicTheory.circle_of_fifths(:c, 4) #=> [60, 67, 62, 69]
    def circle_of_fifths(root, steps = 12)
      raise ArgumentError, "Root note cannot be nil" if root.nil?
      raise ArgumentError, "Steps must be numeric" unless steps.is_a?(Numeric)

      root_midi = Note.resolve_midi_note(root)
      steps_int = steps.to_i

      progression = [root_midi]
      current = root_midi

      interval = steps_int >= 0 ? 7 : 5  # fifths up or fourths down
      steps_int.abs.times do
        current = (current + interval) % 12 + (root_midi / 12) * 12
        progression << current
      end

      progression
    end

    # Find common tones between two chords
    #
    # @param chord1 [Array<Integer>] First chord MIDI notes
    # @param chord2 [Array<Integer>] Second chord MIDI notes
    # @return [Array<Integer>] Common pitch classes (0-11)
    #
    # @example
    #   MusicTheory.common_tones([60, 64, 67], [65, 69, 72])
    def common_tones(chord1, chord2)
      raise ArgumentError, "chord1 must be an array" unless chord1.is_a?(Array)
      raise ArgumentError, "chord2 must be an array" unless chord2.is_a?(Array)

      pc1 = chord1.map { |n| n % 12 }.uniq
      pc2 = chord2.map { |n| n % 12 }.uniq

      pc1 & pc2
    end

    # Calculate harmonic distance between two chords
    # (number of semitone movements in closest voice leading)
    #
    # @param chord1 [Array<Integer>] First chord MIDI notes
    # @param chord2 [Array<Integer>] Second chord MIDI notes
    # @return [Integer] Total semitone distance
    #
    # @example
    #   MusicTheory.harmonic_distance([60, 64, 67], [62, 65, 69])
    def harmonic_distance(chord1, chord2)
      raise ArgumentError, "chord1 must be an array" unless chord1.is_a?(Array)
      raise ArgumentError, "chord2 must be an array" unless chord2.is_a?(Array)
      raise ArgumentError, "Chords must have same number of notes" if chord1.length != chord2.length

      sorted1 = chord1.sort
      sorted2 = chord2.sort

      sorted1.zip(sorted2).sum { |n1, n2| (n1 - n2).abs }
    end

    # Generate a scale from intervals
    #
    # @param root [Object] Root note
    # @param intervals [Array<Integer>] Intervals in semitones
    # @return [Array<Integer>] MIDI notes of scale
    #
    # @example
    #   MusicTheory.scale_from_intervals(:c4, [2, 2, 1, 2, 2, 2, 1])
    def scale_from_intervals(root, intervals)
      raise ArgumentError, "Root note cannot be nil" if root.nil?
      raise ArgumentError, "Intervals must be an array" unless intervals.is_a?(Array)
      raise ArgumentError, "Intervals cannot be empty" if intervals.empty?

      root_midi = Note.resolve_midi_note(root)
      scale = [root_midi]
      current = root_midi

      intervals.each do |interval|
        raise ArgumentError, "Interval must be numeric" unless interval.is_a?(Numeric)
        raise ArgumentError, "Interval must be positive" unless interval > 0

        current += interval
        scale << current
      end

      scale
    end

    # Check if a note is in a scale
    #
    # @param note [Object] Note to check
    # @param scale_notes [Array<Integer>] Scale MIDI notes
    # @return [Boolean] True if note is in scale (by pitch class)
    #
    # @example
    #   MusicTheory.in_scale?(:e4, [60, 62, 64, 65, 67, 69, 71])
    def in_scale?(note, scale_notes)
      raise ArgumentError, "Note cannot be nil" if note.nil?
      raise ArgumentError, "Scale notes must be an array" unless scale_notes.is_a?(Array)

      note_midi = Note.resolve_midi_note(note)
      note_pc = note_midi % 12
      scale_pcs = scale_notes.map { |n| n % 12 }.uniq

      scale_pcs.include?(note_pc)
    end

    # Find the nearest scale degree to a note
    #
    # @param note [Object] Note to quantize
    # @param scale_notes [Array<Integer>] Scale MIDI notes
    # @return [Integer] Nearest scale note (MIDI)
    #
    # @example
    #   MusicTheory.quantize_to_scale(61, [60, 62, 64, 65, 67, 69, 71])
    def quantize_to_scale(note, scale_notes)
      raise ArgumentError, "Note cannot be nil" if note.nil?
      raise ArgumentError, "Scale notes must be an array" unless scale_notes.is_a?(Array)
      raise ArgumentError, "Scale notes cannot be empty" if scale_notes.empty?

      note_midi = Note.resolve_midi_note(note).to_i

      # Extend scale across octaves
      octave = note_midi / 12
      base_octave = scale_notes.min / 12

      extended_scale = []
      (-2..2).each do |oct|
        scale_notes.each do |scale_note|
          pc = scale_note % 12
          extended_scale << (base_octave + oct) * 12 + pc
        end
      end

      # Find closest
      extended_scale.min_by { |scale_note| (scale_note - note_midi).abs }
    end
  end
end
