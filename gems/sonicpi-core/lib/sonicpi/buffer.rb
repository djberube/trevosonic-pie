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
  class Buffer
    attr_reader :id, :num_frames, :num_chans, :sample_rate, :duration
    attr_accessor :path

    def initialize(server, id, num_frames, num_chans, sample_rate)
      # Defensive: validate inputs
      raise ArgumentError, "server cannot be nil" if server.nil?
      raise ArgumentError, "id cannot be nil" if id.nil?
      raise ArgumentError, "num_frames cannot be nil" if num_frames.nil?
      raise ArgumentError, "num_chans cannot be nil" if num_chans.nil?
      raise ArgumentError, "sample_rate cannot be nil" if sample_rate.nil?

      # Defensive: validate numeric parameters
      unless id.is_a?(Numeric)
        raise ArgumentError, "id must be numeric, got #{id.class}"
      end

      unless num_frames.is_a?(Numeric)
        raise ArgumentError, "num_frames must be numeric, got #{num_frames.class}"
      end

      unless num_chans.is_a?(Numeric)
        raise ArgumentError, "num_chans must be numeric, got #{num_chans.class}"
      end

      unless sample_rate.is_a?(Numeric)
        raise ArgumentError, "sample_rate must be numeric, got #{sample_rate.class}"
      end

      # Defensive: validate ranges
      id_int = id.to_i
      num_frames_int = num_frames.to_i
      num_chans_int = num_chans.to_i
      sample_rate_float = sample_rate.to_f

      if id_int < 0
        raise ArgumentError, "id must be non-negative, got #{id}"
      end

      if num_frames_int <= 0
        raise ArgumentError, "num_frames must be positive, got #{num_frames}"
      end

      if num_chans_int <= 0
        raise ArgumentError, "num_chans must be positive, got #{num_chans}"
      end

      if sample_rate_float <= 0
        raise ArgumentError, "sample_rate must be positive, got #{sample_rate}"
      end

      @server = server
      @id = id_int
      @num_frames = num_frames_int
      @num_chans = num_chans_int
      @sample_rate = sample_rate_float

      # Defensive: handle division by zero
      @duration = num_frames_int.to_f / sample_rate_float
      @state = :live
      @mutex = Mutex.new
      @path = nil
    end

    def server
      @server
    end

    def to_i
      @id
    end

    def to_f
      @id.to_f
    end

    def free
      return false if @state == :killed
      @mutex.synchronize do
        return false if @state == :killed
        @state = :killed

        # Defensive: handle errors in buffer_free
        begin
          @server.buffer_free(@id) if @server.respond_to?(:buffer_free)
        rescue => e
          # Log error but don't re-raise - buffer is already marked as killed
          warn "Error freeing buffer #{@id}: #{e.class} - #{e.message}" if $VERBOSE
        end
      end
      self
    end

    def to_s
      if @path
        "#<Buffer @id=#{@id}, @num_chans=#{@num_chans}, @num_frames=#{@num_frames}, @sample_rate=#{@sample_rate}, @duration=#{@duration}, @path=#{@path}>"
      else
        "#<Buffer @id=#{@id}, @num_chans=#{@num_chans}, @num_frames=#{@num_frames}, @sample_rate=#{@sample_rate}, @duration=#{@duration}>"
      end
    end

    def inspect
      to_s
    end

  end
end
