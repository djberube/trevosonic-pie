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

module SonicPi
  # Pattern system inspired by strudel/TidalCycles mini-notation
  #
  # Provides a concise way to express rhythmic and melodic patterns using
  # a mini-notation embedded in strings.
  #
  # @example Basic pattern
  #   Pattern.new("c e g b")
  #
  # @example Pattern with rests
  #   Pattern.new("c ~ g ~")
  #
  # @example Pattern with subdivisions
  #   Pattern.new("c [e g] b")
  class Pattern
    # Custom error classes for better error handling
    class InvalidPatternError < ArgumentError; end
    class InvalidDurationError < ArgumentError; end
    class InvalidNotationError < ArgumentError; end
    class MismatchedBracketsError < InvalidNotationError; end

    attr_reader :notation, :events, :duration

    # Initialize a new pattern from mini-notation string
    #
    # @param notation [String] Mini-notation pattern string
    # @param duration [Numeric] Duration of one complete cycle (default: 1.0)
    # @raise [InvalidNotationError] if notation is nil or empty
    # @raise [InvalidDurationError] if duration is not positive
    def initialize(notation, duration: 1.0)
      validate_notation!(notation)
      validate_duration!(duration)

      @notation = notation.to_s.freeze
      @duration = duration.to_f
      @events = parse(@notation)
      freeze_events
    end

    private

    # Validate notation input
    #
    # @param notation [Object] Notation to validate
    # @raise [InvalidNotationError] if notation is invalid
    def validate_notation!(notation)
      raise InvalidNotationError, "Pattern notation cannot be nil" if notation.nil?

      notation_str = notation.to_s.strip

      # Empty pattern is valid (represents silence)
      return if notation_str.empty?

      # Check for balanced brackets
      validate_balanced_brackets!(notation_str)
    end

    # Validate that brackets are balanced
    #
    # @param notation_str [String] Notation string to validate
    # @raise [MismatchedBracketsError] if brackets are unbalanced
    def validate_balanced_brackets!(notation_str)
      depth = 0
      notation_str.each_char do |char|
        depth += 1 if char == '['
        depth -= 1 if char == ']'

        if depth < 0
          raise MismatchedBracketsError, "Unmatched closing bracket ']' in pattern notation"
        end
      end

      if depth > 0
        raise MismatchedBracketsError, "Unmatched opening bracket '[' in pattern notation (missing #{depth} closing bracket(s))"
      end
    end

    # Validate duration input
    #
    # @param duration [Object] Duration to validate
    # @raise [InvalidDurationError] if duration is invalid
    def validate_duration!(duration)
      raise InvalidDurationError, "Pattern duration cannot be nil" if duration.nil?

      unless duration.is_a?(Numeric)
        raise InvalidDurationError, "Pattern duration must be numeric, got #{duration.class}"
      end

      if duration <= 0
        raise InvalidDurationError, "Pattern duration must be positive, got #{duration}"
      end

      unless duration.finite?
        raise InvalidDurationError, "Pattern duration must be finite, got #{duration}"
      end
    end

    public

    # Parse mini-notation string into events
    #
    # This is a basic implementation that handles:
    # - Space-separated sequences
    # - Rests (~)
    # - Simple subdivisions with []
    # - Polyphony with ,
    #
    # Future versions will add:
    # - Speed operators (* and /)
    # - Alternation (<>)
    # - Elongation (@)
    # - Replication (!)
    # - Randomness (?)
    # - Euclidean rhythms (x,y,z)
    #
    # @param notation [String] Mini-notation pattern string
    # @return [Array<Event>] Parsed events
    def parse(notation)
      tokens = tokenize(notation)
      build_events(tokens, 0.0, @duration)
    end

    # Tokenize the notation string
    #
    # @param str [String] Notation string to tokenize
    # @return [Array] Token tree
    def tokenize(str)
      # Remove outer whitespace
      str = str.strip

      # Simple tokenizer - handles [], and spaces
      # This is a basic implementation
      tokens = []
      current = ""
      depth = 0
      in_brackets = false
      bracket_content = ""

      str.each_char.with_index do |char, idx|
        case char
        when '['
          if depth > 0
            bracket_content << char
          end
          depth += 1
          in_brackets = true

        when ']'
          depth -= 1
          if depth == 0
            tokens << [:subdivision, tokenize(bracket_content)]
            bracket_content = ""
            in_brackets = false
          else
            bracket_content << char
          end

        when ' '
          if in_brackets && depth > 0
            bracket_content << char
          elsif !current.empty?
            tokens << [:token, current]
            current = ""
          end

        else
          if in_brackets && depth > 0
            bracket_content << char
          else
            current << char
          end
        end
      end

      # Add final token if present
      tokens << [:token, current] unless current.empty?

      tokens
    end

    # Build events from token tree
    #
    # @param tokens [Array] Token tree
    # @param start_time [Numeric] Start time for these events
    # @param duration [Numeric] Duration for these events
    # @return [Array<Event>] Built events
    def build_events(tokens, start_time, duration)
      return [] if tokens.nil? || tokens.empty?

      # Defensive checks
      start_time = start_time.to_f
      duration = duration.to_f

      raise InvalidPatternError, "Invalid start_time: #{start_time}" unless start_time.finite?
      raise InvalidDurationError, "Invalid duration: #{duration}" unless duration > 0 && duration.finite?

      events = []
      event_count = tokens.length
      event_duration = duration / event_count

      tokens.each_with_index do |token, idx|
        # Defensive: validate token structure
        unless token.is_a?(Array) && token.length >= 2
          raise InvalidPatternError, "Invalid token structure at index #{idx}"
        end

        event_start = start_time + (idx * event_duration)

        case token[0]
        when :token
          value = token[1]
          next if value.nil? || value.to_s.strip.empty?

          value_str = value.to_s.strip

          if value_str == '~'
            # Rest - add silent event
            events << Event.new(nil, event_start, event_duration, :rest)
          elsif value_str.include?(',')
            # Polyphony - multiple notes at once
            notes = value_str.split(',').map(&:strip).reject(&:empty?)
            if notes.empty?
              raise InvalidPatternError, "Empty chord notation at position #{idx}"
            end
            events << Event.new(notes, event_start, event_duration, :chord)
          else
            # Single note/sample
            events << Event.new(value_str, event_start, event_duration, :note)
          end

        when :subdivision
          # Recursive subdivision with defensive checks
          sub_tokens = token[1]
          if sub_tokens.nil? || (sub_tokens.is_a?(Array) && sub_tokens.empty?)
            # Empty subdivision creates a rest
            events << Event.new(nil, event_start, event_duration, :rest)
          else
            sub_events = build_events(sub_tokens, event_start, event_duration)
            events.concat(sub_events)
          end

        else
          raise InvalidPatternError, "Unknown token type: #{token[0].inspect}"
        end
      end

      events
    end

    # Freeze all events to make pattern immutable
    def freeze_events
      @events.each(&:freeze)
      @events.freeze
    end

    # Get events for a specific cycle
    #
    # @param cycle [Integer] Cycle number (0-indexed)
    # @return [Array<Event>] Events for that cycle
    # @raise [ArgumentError] if cycle is not a valid integer
    def events_for_cycle(cycle)
      unless cycle.is_a?(Numeric)
        raise ArgumentError, "Cycle must be numeric, got #{cycle.class}"
      end

      cycle_int = cycle.to_i
      offset = cycle_int * @duration
      @events.map { |e| e.offset_by(offset) }
    end

    # Reverse the pattern
    #
    # @return [Pattern] New reversed pattern
    def rev
      return Pattern.from_events([], @duration) if @events.empty?

      reversed_events = @events.reverse.map.with_index do |event, idx|
        new_start = (@events.length - idx - 1) * (event.duration)
        Event.new(event.value, new_start, event.duration, event.type)
      end

      Pattern.from_events(reversed_events, @duration)
    end

    # Slow down the pattern by a factor
    #
    # @param factor [Numeric] Slowdown factor (must be positive)
    # @return [Pattern] New slowed pattern
    # @raise [InvalidDurationError] if factor is not positive
    def slow(factor)
      unless factor.is_a?(Numeric) && factor > 0
        raise InvalidDurationError, "Slowdown factor must be positive numeric, got #{factor.inspect}"
      end

      unless factor.finite?
        raise InvalidDurationError, "Slowdown factor must be finite, got #{factor}"
      end

      Pattern.from_events(@events, @duration * factor)
    end

    # Speed up the pattern by a factor
    #
    # @param factor [Numeric] Speedup factor (must be positive)
    # @return [Pattern] New sped-up pattern
    # @raise [InvalidDurationError] if factor is not positive or is zero
    def fast(factor)
      unless factor.is_a?(Numeric) && factor > 0
        raise InvalidDurationError, "Speedup factor must be positive numeric, got #{factor.inspect}"
      end

      unless factor.finite?
        raise InvalidDurationError, "Speedup factor must be finite, got #{factor}"
      end

      slow(1.0 / factor)
    end

    # Rotate the pattern by n events
    #
    # @param n [Integer] Number of events to rotate
    # @return [Pattern] New rotated pattern
    # @raise [ArgumentError] if n is not numeric
    def rotate(n)
      return self if @events.empty?

      unless n.is_a?(Numeric)
        raise ArgumentError, "Rotation amount must be numeric, got #{n.class}"
      end

      n_int = n.to_i % @events.length
      rotated = @events.rotate(n_int)

      # Recalculate event times
      new_events = rotated.map.with_index do |event, idx|
        new_start = idx * event.duration
        Event.new(event.value, new_start, event.duration, event.type)
      end

      Pattern.from_events(new_events, @duration)
    end

    # Create pattern from events array
    #
    # @param events [Array<Event>] Event array
    # @param duration [Numeric] Pattern duration
    # @return [Pattern] New pattern
    # @raise [InvalidPatternError] if events is not an array
    # @raise [InvalidDurationError] if duration is invalid
    def self.from_events(events, duration)
      unless events.is_a?(Array)
        raise InvalidPatternError, "Events must be an array, got #{events.class}"
      end

      unless duration.is_a?(Numeric) && duration > 0 && duration.finite?
        raise InvalidDurationError, "Duration must be positive and finite, got #{duration.inspect}"
      end

      # Validate all events
      events.each_with_index do |event, idx|
        unless event.is_a?(Event)
          raise InvalidPatternError, "Event at index #{idx} must be a Pattern::Event, got #{event.class}"
        end
      end

      pattern = allocate
      pattern.instance_variable_set(:@events, events.dup.freeze)
      pattern.instance_variable_set(:@duration, duration.to_f)
      pattern.instance_variable_set(:@notation, "(constructed)")
      pattern
    end

    # String representation
    #
    # @return [String] Pattern representation
    def to_s
      "Pattern(#{@notation.inspect})"
    end

    # Detailed inspection
    #
    # @return [String] Detailed pattern info
    def inspect
      "Pattern(#{@notation.inspect}, #{@events.length} events, #{@duration}s)"
    end

    # Equality comparison
    #
    # @param other [Pattern] Other pattern to compare
    # @return [Boolean] True if patterns are equal
    def ==(other)
      return false unless other.is_a?(Pattern)

      @notation == other.notation &&
        @duration == other.duration &&
        @events == other.events
    end

    alias_method :eql?, :==

    # Hash code for use in hashes and sets
    #
    # @return [Integer] Hash code
    def hash
      [@notation, @duration, @events].hash
    end

    # Freeze the pattern (already immutable)
    #
    # @return [Pattern] Self
    def freeze
      super
      self
    end

    # Check if pattern is frozen (always true)
    #
    # @return [Boolean] True
    def frozen?
      true
    end

    # Enumerate events
    #
    # @yield [Event] Each event
    # @return [Enumerator] Event enumerator
    def each(&block)
      return enum_for(:each) unless block_given?

      @events.each(&block)
    end

    # Include Enumerable for Ruby compatibility
    include Enumerable

    # Get event at index
    #
    # @param index [Integer] Event index
    # @return [Event, nil] Event at index or nil
    def [](index)
      return nil unless index.is_a?(Numeric)

      @events[index.to_i]
    end

    # Pattern length (number of events)
    #
    # @return [Integer] Number of events
    def length
      @events.length
    end

    alias_method :size, :length

    # Check if pattern is empty
    #
    # @return [Boolean] True if no events
    def empty?
      @events.empty?
    end

    # Convert to array of events
    #
    # @return [Array<Event>] Events array
    def to_a
      @events.dup
    end

    # Marshal dumping support
    #
    # @return [Array] Marshallable data
    def marshal_dump
      [@notation, @duration, @events]
    end

    # Marshal loading support
    #
    # @param data [Array] Marshalled data
    def marshal_load(data)
      @notation, @duration, @events = data
    end

    # Event represents a single musical event in a pattern
    class Event
      # Valid event types
      VALID_TYPES = [:note, :chord, :rest, :sample].freeze

      attr_reader :value, :start, :duration, :type

      # Initialize an event
      #
      # @param value [Object] Note, sample, or array of notes (for chords)
      # @param start [Numeric] Start time within pattern cycle
      # @param duration [Numeric] Duration of event
      # @param type [Symbol] Event type (:note, :chord, :rest, :sample)
      # @raise [ArgumentError] if parameters are invalid
      def initialize(value, start, duration, type)
        validate_start!(start)
        validate_duration!(duration)
        validate_type!(type)
        validate_value!(value, type)

        @value = freeze_value(value)
        @start = start.to_f
        @duration = duration.to_f
        @type = type
        freeze
      end

      private

      # Validate start time
      def validate_start!(start)
        unless start.is_a?(Numeric)
          raise ArgumentError, "Event start must be numeric, got #{start.class}"
        end

        unless start.finite?
          raise ArgumentError, "Event start must be finite, got #{start}"
        end

        if start < 0
          raise ArgumentError, "Event start must be non-negative, got #{start}"
        end
      end

      # Validate duration
      def validate_duration!(duration)
        unless duration.is_a?(Numeric)
          raise ArgumentError, "Event duration must be numeric, got #{duration.class}"
        end

        unless duration > 0 && duration.finite?
          raise ArgumentError, "Event duration must be positive and finite, got #{duration}"
        end
      end

      # Validate event type
      def validate_type!(type)
        unless VALID_TYPES.include?(type)
          raise ArgumentError, "Invalid event type #{type.inspect}, must be one of #{VALID_TYPES.inspect}"
        end
      end

      # Validate value based on type
      def validate_value!(value, type)
        case type
        when :rest
          # Rests should have nil value
          unless value.nil?
            raise ArgumentError, "Rest event must have nil value, got #{value.inspect}"
          end
        when :chord
          # Chords should have array value
          unless value.is_a?(Array)
            raise ArgumentError, "Chord event must have array value, got #{value.class}"
          end
          if value.empty?
            raise ArgumentError, "Chord event cannot have empty array value"
          end
        when :note, :sample
          # Notes and samples should not be nil or empty
          if value.nil?
            raise ArgumentError, "#{type.capitalize} event cannot have nil value"
          end
          if value.to_s.strip.empty?
            raise ArgumentError, "#{type.capitalize} event cannot have empty value"
          end
        end
      end

      # Freeze value to make it immutable
      def freeze_value(value)
        if value.is_a?(Array)
          value.map(&:freeze).freeze
        elsif value.nil?
          nil
        else
          value.freeze
        end
      end

      public

      # Create new event offset by time
      #
      # @param offset [Numeric] Time offset
      # @return [Event] New offset event
      # @raise [ArgumentError] if offset is invalid
      def offset_by(offset)
        unless offset.is_a?(Numeric)
          raise ArgumentError, "Offset must be numeric, got #{offset.class}"
        end

        unless offset.finite?
          raise ArgumentError, "Offset must be finite, got #{offset}"
        end

        Event.new(@value, @start + offset, @duration, @type)
      end

      # Check if event is a rest
      #
      # @return [Boolean] True if rest
      def rest?
        @type == :rest
      end

      # Check if event is a chord
      #
      # @return [Boolean] True if chord
      def chord?
        @type == :chord
      end

      # Check if event is a note
      #
      # @return [Boolean] True if note
      def note?
        @type == :note
      end

      # Check if event is a sample
      #
      # @return [Boolean] True if sample
      def sample?
        @type == :sample
      end

      # String representation
      #
      # @return [String] Event representation
      def to_s
        case @type
        when :rest
          "~"
        when :chord
          "[#{@value.join(',')}]"
        else
          @value.to_s
        end
      end

      # Detailed inspection
      #
      # @return [String] Detailed event info
      def inspect
        "Event(#{to_s}, @#{@start.round(4)}, #{@duration.round(4)}s)"
      end

      # Equality comparison
      #
      # @param other [Event] Other event to compare
      # @return [Boolean] True if events are equal
      def ==(other)
        return false unless other.is_a?(Event)

        @value == other.value &&
          @start == other.start &&
          @duration == other.duration &&
          @type == other.type
      end

      alias_method :eql?, :==

      # Hash code for use in hashes and sets
      #
      # @return [Integer] Hash code
      def hash
        [@value, @start, @duration, @type].hash
      end

      # Convert to hash (for JSON/YAML serialization)
      #
      # @return [Hash] Event as hash
      def to_h
        {
          value: @value,
          start: @start,
          duration: @duration,
          type: @type
        }
      end

      # Marshal dumping support
      #
      # @return [Array] Marshallable data
      def marshal_dump
        [@value, @start, @duration, @type]
      end

      # Marshal loading support
      #
      # @param data [Array] Marshalled data
      def marshal_load(data)
        @value, @start, @duration, @type = data
      end
    end
  end
end

