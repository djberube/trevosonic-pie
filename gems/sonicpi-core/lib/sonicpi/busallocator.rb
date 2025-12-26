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
require_relative "bus"
require_relative "allocator"

module SonicPi
  class BusAllocator
    def initialize(max_bus_id, idx_offset = 0)
      # Defensive: validate inputs
      raise ArgumentError, "max_bus_id cannot be nil" if max_bus_id.nil?

      unless max_bus_id.is_a?(Numeric)
        raise ArgumentError, "max_bus_id must be numeric, got #{max_bus_id.class}"
      end

      unless idx_offset.is_a?(Numeric)
        raise ArgumentError, "idx_offset must be numeric, got #{idx_offset.class}"
      end

      max_bus_id_int = max_bus_id.to_i
      idx_offset_int = idx_offset.to_i

      # Defensive: validate ranges
      if max_bus_id_int <= 0
        raise ArgumentError, "max_bus_id must be positive, got #{max_bus_id}"
      end

      if idx_offset_int < 0
        raise ArgumentError, "idx_offset must be non-negative, got #{idx_offset}"
      end

      if idx_offset_int >= max_bus_id_int
        raise ArgumentError, "idx_offset (#{idx_offset_int}) must be less than max_bus_id (#{max_bus_id_int})"
      end

      # allocate busses in pairs
      alloc_size = allocation_size

      # Defensive: validate allocation_size
      unless alloc_size.is_a?(Numeric) && alloc_size.to_i > 0
        raise RuntimeError, "allocation_size must return a positive integer, got #{alloc_size.inspect}"
      end

      @allocation_size = alloc_size.to_i
      @idx_offset = idx_offset_int

      # Defensive: validate calculation doesn't underflow
      available_ids = max_bus_id_int - idx_offset_int
      if available_ids <= 0
        raise ArgumentError, "No bus IDs available (max_bus_id: #{max_bus_id_int}, idx_offset: #{idx_offset_int})"
      end

      @max_id = (available_ids / @allocation_size) - 1

      # Defensive: ensure we have at least one allocatable slot
      if @max_id < 0
        raise ArgumentError, "Insufficient bus IDs for allocation_size (#{@allocation_size})"
      end

      @allocator = Allocator.new(@max_id + 1)
    end

    def allocation_size
      1
    end

    def allocate
      # Defensive: catch allocation errors
      begin
        alloc_idx = @allocator.allocate
      rescue AllocationError => e
        raise AllocationError, "Bus allocation failed: #{e.message}"
      end

      # Defensive: validate calculated ID
      new_id = (alloc_idx * @allocation_size) + @idx_offset

      # Defensive: ensure bus_class is implemented
      klass = bus_class
      unless klass.respond_to?(:new)
        raise NotImplementedError, "bus_class must return a class with a .new method"
      end

      bus_class.new(new_id, self)
    rescue => e
      # Defensive: release allocation on error
      @allocator.release!(alloc_idx) if alloc_idx
      raise
    end

    def release!(id)
      # Defensive: validate id
      return false if id.nil?

      unless id.is_a?(Numeric)
        raise ArgumentError, "Bus ID must be numeric, got #{id.class}"
      end

      id_int = id.to_i

      # Defensive: validate range
      if id_int < @idx_offset
        raise ArgumentError, "Bus ID #{id_int} below offset #{@idx_offset}"
      end

      idx = (id_int - @idx_offset) / @allocation_size

      # Defensive: catch errors from underlying allocator
      begin
        @allocator.release!(idx)
      rescue => e
        raise AllocationError, "Failed to release bus #{id_int}: #{e.message}"
      end
    end

    def reset!
      @allocator.reset!
    end

    def num_busses_allocated
      @allocator.num_allocations
    end

    def to_s
      "<#SonicPi::BusAllocator>"
    end

    private

    def bus_class
      raise "Implement me!"
    end
  end
end
