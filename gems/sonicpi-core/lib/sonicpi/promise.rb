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
require 'thread'

## Note: this promise implementation is modelled on the semantics of
## Clojure's promise.  See: https://clojuredocs.org/clojure.core/promise

module SonicPi
  class PromiseTimeoutError < StandardError ; end
  class PromiseAlreadyDeliveredError < StandardError ; end

  class Promise
    def initialize
      @prom_sem = Mutex.new
      @value = nil
      @delivered = false
      @received = ConditionVariable.new
    end

    def get(timeout = nil)
      return @value if @delivered

      # Defensive: validate timeout
      if timeout && !timeout.is_a?(Numeric)
        raise ArgumentError, "timeout must be numeric or nil, got #{timeout.class}"
      end

      if timeout && timeout.to_f < 0
        raise ArgumentError, "timeout must be non-negative, got #{timeout}"
      end

      @prom_sem.synchronize do
        return @value if @delivered

        # Defensive: handle interrupts
        begin
          @received.wait(@prom_sem, timeout)
        rescue => e
          raise PromiseTimeoutError, "Promise wait interrupted: #{e.message}"
        end

        if @delivered
          @value
        else
          raise PromiseTimeoutError, "Promise timed out after #{timeout} seconds."
        end
      end
    end

    def deliver!(val, raise_error = true)
      @prom_sem.synchronize do
        if @delivered
          if raise_error
            raise PromiseAlreadyDeliveredError, "Promise already delivered. You tried to deliver #{val.inspect}, however already have: #{@value.inspect}"
          end
          # Defensive: return existing value if not raising error
          @value
        else
          @value = val
          @delivered = true

          # Defensive: handle broadcast errors
          begin
            @received.broadcast
          rescue => e
            # If broadcast fails, we should still mark as delivered
            # but log the error
            warn "Error broadcasting promise delivery: #{e.class} - #{e.message}" if $VERBOSE
          end

          val
        end
      end
    end

    def delivered?
      @delivered
    end

    def to_s
      "<Promise delivered: #{@delivered}>"
    end
  end
end
