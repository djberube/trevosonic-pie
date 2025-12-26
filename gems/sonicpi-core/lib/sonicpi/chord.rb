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
require_relative 'wrappingarray'

module SonicPi
  class Chord < WrappingArray
    # Ported from Overtone: https://github.com/overtone/overtone/blob/master/src/overtone/music/pitch.clj

    CHORD, CHORD_LOOKUP, CHORD_NAMES = lambda do
      major   = [0, 4, 7]
      minor   = [0, 3, 7]
      major7  = [0, 4, 7, 11]
      dom7    = [0, 4, 7, 10]
      minor7  = [0, 3, 7, 10]
      aug     = [0, 4, 8]
      dim     = [0, 3, 6]
      dim7    = [0, 3, 6, 9]
      halfdim = [0, 3, 6, 10]
      all_chords = {
        "1"              => [0],
        "5"              => [0, 7],
        "+5"             => [0, 4, 8],
        "m+5"            => [0, 3, 8],
        :sus2            => [0, 2, 7],
        :sus4            => [0, 5, 7],
        "6"              => [0, 4, 7, 9],
        :m6              => [0, 3, 7, 9],
        "7sus2"          => [0, 2, 7, 10],
        "7sus4"          => [0, 5, 7, 10],
        "7-5"            => [0, 4, 6, 10],
        :halfdiminished  => halfdim,
        "7+5"            => [0, 4, 8, 10],
        "m7+5"           => [0, 3, 8, 10],
        "9"              => [0, 4, 7, 10, 14],
        :m9              => [0, 3, 7, 10, 14],
        "m7+9"           => [0, 3, 7, 10, 14],
        :maj9            => [0, 4, 7, 11, 14],
        "9sus4"          => [0, 5, 7, 10, 14],
        "6*9"            => [0, 4, 7, 9, 14],
        "m6*9"           => [0, 3, 7, 9, 14],
        "7-9"            => [0, 4, 7, 10, 13],
        "m7-9"           => [0, 3, 7, 10, 13],
        "7-10"           => [0, 4, 7, 10, 15],
        "7-11"           => [0, 4, 7, 10, 16],
        "7-13"           => [0, 4, 7, 10, 20],
        "9+5"            => [0, 10, 13],
        "m9+5"           => [0, 10, 14],
        "7+5-9"          => [0, 4, 8, 10, 13],
        "m7+5-9"         => [0, 3, 8, 10, 13],
        "11"             => [0, 4, 7, 10, 14, 17],
        :m11             => [0, 3, 7, 10, 14, 17],
        :maj11           => [0, 4, 7, 11, 14, 17],
        "11+"            => [0, 4, 7, 10, 14, 18],
        "m11+"           => [0, 3, 7, 10, 14, 18],
        "13"             => [0, 4, 7, 10, 14, 17, 21],
        :m13             => [0, 3, 7, 10, 14, 17, 21],
        :add2            => [0, 2, 4, 7],
        :add4            => [0, 4, 5, 7],
        :add9            => [0, 4, 7, 14],
        :add11           => [0, 4, 7, 17],
        :add13           => [0, 4, 7, 21],
        :madd2           => [0, 2, 3, 7],
        :madd4           => [0, 3, 5, 7],
        :madd9           => [0, 3, 7, 14],
        :madd11          => [0, 3, 7, 17],
        :madd13          => [0, 3, 7, 21],
        :major           => major,
        :maj             => major,
        :M               => major,
        :minor           => minor,
        :min             => minor,
        :m               => minor,
        :major7          => major7,
        :dom7            => dom7,
        "7"              => dom7,
        :M7              => major7,
        :minor7          => minor7,
        :m7              => minor7,
        :augmented       => aug,
        :a               => aug,
        :diminished      => dim,
        :dim             => dim,
        :i               => dim,
        :diminished7     => dim7,
        :dim7            => dim7,
        :i7              => dim7,
        :halfdim         => halfdim,
        "m7b5"           => halfdim,
        "m7-5" => halfdim
      }

      all_chords_lookup = all_chords.inject({}) do |res, chord_intervals|
        k, v = *chord_intervals
        res[k.to_sym] = v
        res
      end

      all_chords_names = all_chords.inject([]) do |res, chord_intervals|
        k, _v = *chord_intervals
        res << k.to_s
        res
      end

      return all_chords, all_chords_lookup, all_chords_names.sort
    end.call

    attr_reader :tonic, :notes, :num_octaves

    def self.resolve_degree(degree, tonic, name, no_of_notes)
      # Defensive: validate inputs
      raise ArgumentError, "Degree cannot be nil" if degree.nil?
      raise ArgumentError, "Tonic cannot be nil" if tonic.nil?
      raise ArgumentError, "Scale name cannot be nil" if name.nil?
      raise ArgumentError, "Number of notes cannot be nil" if no_of_notes.nil?

      # Defensive: validate no_of_notes
      unless no_of_notes.is_a?(Numeric)
        raise ArgumentError, "Number of notes must be numeric, got #{no_of_notes.class}"
      end

      no_of_notes_int = no_of_notes.to_i
      if no_of_notes_int <= 0
        raise ArgumentError, "Number of notes must be positive, got #{no_of_notes}"
      end

      name_str = name.to_s
      degree_int = Scale.resolve_degree_index(degree)
      scale = Scale.resolve_scale(tonic, name_str, 2)

      # Defensive: validate scale
      if scale.nil? || scale.notes.nil? || scale.notes.empty?
        raise ArgumentError, "Invalid scale for tonic #{tonic.inspect} and name #{name.inspect}"
      end

      # Build chord from scale degrees
      available_notes = scale.notes.drop(degree_int).select.with_index { |_, i| i % 2 == 0 }

      # Defensive: check if we have enough notes
      if available_notes.length < no_of_notes_int
        # Extend by adding octaves if needed
        while available_notes.length < no_of_notes_int
          last_note = available_notes.last
          available_notes << last_note + 12
        end
      end

      available_notes.take(no_of_notes_int)
    end

    def initialize(tonic, name, num_octaves=1)
      # Defensive: validate inputs
      raise ArgumentError, "Tonic cannot be nil" if tonic.nil?
      raise ArgumentError, "Chord name cannot be nil" if name.nil?

      # Defensive: ensure num_octaves is valid
      num_octaves = 1 unless num_octaves

      unless num_octaves.is_a?(Numeric)
        raise ArgumentError, "Number of octaves must be numeric, got #{num_octaves.class}"
      end

      num_octaves_int = num_octaves.to_i
      if num_octaves_int <= 0
        raise ArgumentError, "Number of octaves must be positive, got #{num_octaves}"
      end

      # Convert name to symbol
      name_sym = name.to_sym

      # Defensive: look up intervals
      intervals = CHORD_LOOKUP[name_sym]
      raise "Unknown chord name: #{name.inspect}" unless intervals

      # Defensive: validate intervals
      unless intervals.is_a?(Array)
        raise ArgumentError, "Chord intervals must be an array for #{name.inspect}"
      end

      if intervals.empty?
        raise ArgumentError, "Chord intervals cannot be empty for #{name.inspect}"
      end

      # Defensive: resolve tonic
      begin
        tonic_midi = Note.resolve_midi_note_without_octave(tonic)
      rescue => e
        raise ArgumentError, "Invalid tonic #{tonic.inspect}: #{e.message}"
      end

      raise ArgumentError, "Could not resolve tonic #{tonic.inspect}" if tonic_midi.nil?

      # Build chord
      res = []
      num_octaves_int.times do |octave_num|
        intervals.each_with_index do |interval, idx|
          # Defensive: validate interval
          unless interval.is_a?(Numeric)
            raise ArgumentError, "Interval at index #{idx} must be numeric, got #{interval.class}"
          end

          if interval < 0
            raise ArgumentError, "Interval at index #{idx} must be non-negative, got #{interval}"
          end

          res << tonic_midi + interval + (octave_num * 12)
        end
      end

      @name = name_sym
      @tonic = tonic_midi
      @notes = res.freeze
      @num_octaves = num_octaves_int
      super(res)
    end

    def name
      @name.to_s
    end

    def to_s
      "#<SonicPi::Chord :#{Note.resolve_note_name(@tonic)} :#{@name} #{@notes}>"
    end

    def inspect
      to_s
    end
  end
end
