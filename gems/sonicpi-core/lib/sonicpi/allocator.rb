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
  class AllocationError < StandardError; end

  class Allocator
    attr_reader :max_id

    def initialize(max_id)
      # Defensive: validate max_id
      raise ArgumentError, "max_id cannot be nil" if max_id.nil?

      unless max_id.is_a?(Numeric)
        raise ArgumentError, "max_id must be numeric, got #{max_id.class}"
      end

      max_id_int = max_id.to_i
      if max_id_int <= 0
        raise ArgumentError, "max_id must be positive, got #{max_id}"
      end

      # Defensive: prevent excessive memory allocation
      if max_id_int > 1_000_000
        raise ArgumentError, "max_id too large (#{max_id_int}), maximum is 1,000,000"
      end

      @max_id = max_id_int
      @mut = Mutex.new
      @last_used_idx = 0
      reset!
    end

    def allocate
      @mut.synchronize do
        attempts = 0

        # Defensive: ensure allocations array exists
        unless @allocations
          raise RuntimeError, "Allocations array not initialized"
        end

        while attempts < @max_id
          @last_used_idx = (@last_used_idx + 1) % @max_id

          # Defensive: validate index bounds
          if @last_used_idx < 0 || @last_used_idx >= @max_id
            raise RuntimeError, "Allocation index out of bounds: #{@last_used_idx}"
          end

          if @allocations[@last_used_idx] == false
            @allocations[@last_used_idx] = true
            return @last_used_idx
          end
          attempts += 1
        end
      end

      # Defensive: provide informative error message
      raise AllocationError, "No free allocations available (max_id: #{@max_id}, current usage: #{num_allocations})"
    end

    def release!(idx)
      # Defensive: validate idx
      return false if idx.nil?

      unless idx.is_a?(Numeric)
        raise ArgumentError, "Index must be numeric, got #{idx.class}"
      end

      idx_int = idx.to_i

      # Defensive: validate bounds
      if idx_int < 0 || idx_int >= @max_id
        raise ArgumentError, "Index out of bounds: #{idx_int} (valid range: 0..#{@max_id - 1})"
      end

      @mut.synchronize do
        # Defensive: check if already released
        if @allocations[idx_int] == false
          # Already released, but this is not an error - just a no-op
          return false
        end

        @allocations[idx_int] = false
        true
      end
    end

    def reset!
      @mut.synchronize do
        @allocations = [false] * @max_id
      end
    end

    def num_allocations
      # Defensive: handle uninitialized state
      return 0 unless @allocations

      @mut.synchronize do
        @allocations.count { |v| v == true }
      end
    end

    def to_s
      "<#SonicPi::Allocator>"
    end

    def inspect
      to_s
    end
  end
end
