#--
# This file is part of Sonic Pi: http://sonic-pi.net
# Full project source: https://github.com/samaaron/sonic-pi
# License: https://github.com/samaaron/sonic-pi/blob/main/LICENSE.md
#
# Copyright 2017 by Sam Aaron (http://sam.aaron.name).
# All rights reserved.
#
# Permission is granted for use, copying, modification, and
# distribution of modified versions of this work as long as this
# notice is included.
#++

require_relative "cueevent"
require 'timeout'

module SonicPi

  module EventMatcherUtil
    def safe_matcher_call(matcher, event)
      return true unless matcher
      begin
        return matcher.call(event)
      rescue Exception
        return false
      end
    end
  end

  class EventHistoryNode
    attr_accessor :children, :events

    def initialize
      @children = {}
      @events = []
    end

    def count_nodes(node_total=0, event_total=0)
      node_total += 1
      event_total += @events.size

      @children.each do |k, n|
        nt, et = n.count_nodes(0, 0)
        node_total += nt
        event_total += et
      end

      [node_total, event_total]
    end
  end

  class EventMatcher
    include EventMatcherUtil

    attr_reader :handle, :prom, :ce

     def initialize(ce, val_matcher=nil, handle=nil, prom=nil)
       # Defensive: validate inputs
       raise ArgumentError, "ce cannot be nil" if ce.nil?
       raise ArgumentError, "ce must be a CueEvent" unless ce.is_a?(CueEvent)
       raise ArgumentError, "val_matcher must be callable or nil" if val_matcher && !val_matcher.respond_to?(:call)

       path = String.new(ce.path)

       # get rid of white space
       path.strip!

       # remove initial / if present
       path[0] = '' if path.start_with?('/')

       path = Regexp.escape(path)

       # replace glob-style ** with regexp .*
       path.gsub!(/\/\s*\\\*\\\*\s*\//, '/.*/')

       # replace ** at end of string (sans /) with .*
       path.gsub!(/\/\s*\\\*\\\*\s*\Z/, '/.*')

       # handle standard *foo, bar* and baz*boz
       path.gsub!(/(?<!\.)\\\*/, '[^/]*')

       # handle word options /{foo,bar}/baz
       path.gsub!(/\\\{([^\/]*)\\\}/, '(\1)')

       # handle char ranges /[a-g]oo/baz/
       path.gsub!(/\\\[!([^\/]*)\\\]/, '[^\1]')

       # handle negative char ranges /[!a-g]/baz
       path.gsub!(/\\\[([^!\/]+[^\/]*)\\\]/, '[\1]')

       # swap , for | and unescape - for char ranges
       path.gsub!(',', '|')
       path.gsub!('\\-', '-')

       # handle single chars /?oo/baz/
       path.gsub!('\\?', '.')

       # convert to a regexp
       matcher_str = "\\A/?#{path}/?\\Z"

       begin
         @matcher = Regexp.new(matcher_str)
       rescue RegexpError => e
         raise ArgumentError, "Invalid path pattern for matching: #{e.message}"
       end

       @val_matcher = val_matcher
       @alive = true
       @prom = prom
       @handle = handle
       @ce = ce
     end

    def kill
      @alive = false
    end

    def dead?
      !@alive
    end

    def path_match(path, val=:sonic_pi_no_match_val)

      if @val_matcher && (val != :sonic_pi_no_match_val)
        @matcher.match(path) && safe_matcher_call(@val_matcher, val)
      else
        @matcher.match(path)
      end
    end
  end


  class EventMatchers
    attr_reader :matchers

    def initialize
      @matchers = []
    end

    def put(ce, val_matcher, thread_id, prom)
      matcher = EventMatcher.new(ce, val_matcher, thread_id, prom)
      @matchers << matcher
      return matcher
    end

    def match(ce)
      @matchers.delete_if do |matcher|
        if matcher.path_match(ce.path, ce.val) && ce > matcher.ce
          matcher.prom.deliver! true if matcher.prom
          matched = true
        else
          matched = false
        end
        matcher.dead? || matched
      end
    end

    def prune(handle_to_remove)
      @matchers.delete_if { |m| m.dead? || m.handle == handle_to_remove }
    end
  end



  # EventHistory manages a tree-based history of cue events with pattern matching and synchronization.
  #
  # This class provides thread-safe storage and retrieval of events organized in a hierarchical
  # structure based on event paths. It supports glob-style pattern matching for flexible event
  # querying and synchronization primitives for coordinating between threads.
  #
  # Key features:
  # - Hierarchical event storage with automatic trimming
  # - Glob pattern matching (**/*/?/[ranges])
  # - Thread-safe operations with mutex protection
  # - Synchronization methods (sync, sync_first, sync_all)
  # - Configurable history depth and trimming
  #
  # @example Basic usage
  #   history = EventHistory.new
  #   history.set(0, 0, thread_id, 0, 0, 60, "/cue/start", [:data])
  #   event = history.get(1, 0, thread_id, 0, 0, 60, "/cue/start")
  #
  # @example Pattern matching
  #   history.set(0, 0, thread_id, 0, 0, 60, "/foo/bar", [:data])
  #   event = history.get(1, 0, thread_id, 0, 0, 60, "/foo/*") # Matches /foo/bar
  #
  # @example Synchronization
  #   # Wait for a specific event
  #   event = history.sync(0, 0, thread_id, 0, 0, 60, "/cue/go")
  #
  #   # Wait for first of multiple events
  #   event = history.sync_first(0, 0, thread_id, 0, 0, 60, ["/cue/a", "/cue/b"])
  #
  #   # Wait for all events
  #   event = history.sync_all(0, 0, thread_id, 0, 0, 60, ["/cue/x", "/cue/y"])
  class EventHistory
    include EventMatcherUtil
    include Util

    # @return [EventMatchers] The event matchers for synchronization
    attr_accessor :event_matchers

    # Initialize a new EventHistory instance.
    #
    # @param trim_history [Boolean] Whether to automatically trim old events (default: true)
    # @param min_history_size [Integer] Minimum number of events to keep per node (default: 20)
    # @param history_depth [Numeric] Maximum age in seconds for events before trimming (default: 32)
    # @raise [ArgumentError] If min_history_size is not positive or history_depth is not positive
    def initialize(trim_history: true, min_history_size: 20, history_depth: 32)
      # Defensive: validate parameters
      raise ArgumentError, "min_history_size must be a positive integer" unless min_history_size.is_a?(Integer) && min_history_size > 0
      raise ArgumentError, "history_depth must be a positive number" unless history_depth.is_a?(Numeric) && history_depth > 0

      @trim_history = !!trim_history  # Ensure boolean
      @min_history_size = min_history_size
      @history_depth = history_depth
      @state = EventHistoryNode.new
      @event_matchers = EventMatchers.new
      @process_mut = Mutex.new
      @matcher_mut = Mutex.new
      @sync_notification_mut = Mutex.new
      @sync_notifiers = Hash.new([])
      @get_mut = Mutex.new
    end

    def size_info
      s = @state.count_nodes
      "nodes: #{s[0]}, events: #{s[1]}"
    end

     # Get the last seen version (at or before the current time)
     def get(t, p, i, d, b, m, path, val_matcher=nil, get_next=false)
       # Defensive: validate inputs
       raise ArgumentError, "time must be numeric" unless t.is_a?(Numeric)
       raise ArgumentError, "priority must be numeric" unless p.is_a?(Numeric)
       raise ArgumentError, "delta must be numeric" unless d.is_a?(Numeric)
       raise ArgumentError, "beat must be numeric" unless b.is_a?(Numeric)
       raise ArgumentError, "bpm must be numeric" unless m.is_a?(Numeric)
       raise ArgumentError, "path cannot be nil" if path.nil?
       raise ArgumentError, "val_matcher must be callable or nil" if val_matcher && !val_matcher.respond_to?(:call)

       wait_for_threads(t)
       res = nil
       begin
         get_event = CueEvent.new(t, p, i, d, b, m, path, [])
       rescue => e
         raise ArgumentError, "Invalid get parameters: #{e.message}"
       end
       res = get_w_mutex(get_event, val_matcher, get_next)
       return res
     end

     # Get next version (after current time)
     # return nil if nothing found
     def get_next(t, p, i, d, b, m, path, val_matcher=nil)
       get(t, p, i, d, b, m, path, val_matcher, true)
     end

     # Register cue event for time t
     # Do not modify time
     def set(t, p, i, d, b, m, path, val)
       # Defensive: validate inputs
       raise ArgumentError, "time must be numeric" unless t.is_a?(Numeric)
       raise ArgumentError, "priority must be numeric" unless p.is_a?(Numeric)
       raise ArgumentError, "delta must be numeric" unless d.is_a?(Numeric)
       raise ArgumentError, "beat must be numeric" unless b.is_a?(Numeric)
       raise ArgumentError, "bpm must be numeric" unless m.is_a?(Numeric)
       raise ArgumentError, "path cannot be nil" if path.nil?

       begin
         ce = CueEvent.new(t, p, i, d, b, m, path, val)
       rescue => e
         raise ArgumentError, "Invalid cue event parameters: #{e.message}"
       end

       @process_mut.synchronize do
         __insert_event!(ce)
       end
       @matcher_mut.synchronize do
         @event_matchers.match(ce)
       end
     end

     # Get the next version (after the current time)
     # Set time to time of cue

     def sync(t, p, i, d, b, m, path, val_matcher=nil)
       # Defensive: validate inputs
       raise ArgumentError, "time must be numeric" unless t.is_a?(Numeric)
       raise ArgumentError, "priority must be numeric" unless p.is_a?(Numeric)
       raise ArgumentError, "delta must be numeric" unless d.is_a?(Numeric)
       raise ArgumentError, "beat must be numeric" unless b.is_a?(Numeric)
       raise ArgumentError, "bpm must be numeric" unless m.is_a?(Numeric)
       raise ArgumentError, "path cannot be nil" if path.nil?
       raise ArgumentError, "val_matcher must be callable or nil" if val_matcher && !val_matcher.respond_to?(:call)

       wait_for_threads(t)
       prom = nil
       begin
         ge = CueEvent.new(t, p, i, d, b, m, path, [])
       rescue => e
         raise ArgumentError, "Invalid sync parameters: #{e.message}"
       end
       res = get_w_mutex(ge, val_matcher, true)
       return res if res
       prom = Promise.new
       @matcher_mut.synchronize do
         @event_matchers.put ge, val_matcher, i, prom
       end
       begin
         prom.get
       rescue => e
         raise RuntimeError, "sync failed: #{e.message}"
       end
       # have to do a get_next again in case
       # an event with an earlier timestamp arrived
       # after this one
       wait_for_threads(t)
       res = get_w_mutex(ge, val_matcher, true)
       if res
         return res
       end
       raise "sync error - couldn't find result for #{[t.to_f, i, p, d, b, path]}"
     end

     # Wait for the first out of the list of cues to arrive.
     #
     # This method blocks until any one of the specified paths receives an event.
     # Once the first event arrives, it returns immediately without waiting for the others.
     #
     # @param t [Numeric] Time parameter
     # @param p [Numeric] Priority parameter
     # @param i [ThreadId] Thread identifier
     # @param d [Numeric] Delta parameter
     # @param b [Numeric] Beat parameter
     # @param m [Numeric] BPM parameter
     # @param paths [Array<String>] Array of paths to wait for
     # @param val_matcher [Proc, nil] Optional value matcher lambda
     # @param timeout [Numeric, nil] Timeout in seconds, or nil for no timeout
     # @return [CueEvent] The first event that arrived
     # @raise [ArgumentError] If paths is invalid or timeout is invalid
     # @raise [Timeout::Error] If timeout expires before any event arrives
     # @raise [RuntimeError] If no matching event is found after synchronization
     def sync_first(t, p, i, d, b, m, paths, val_matcher, timeout=nil)
       # Defensive programming: validate inputs
       raise ArgumentError, "paths must be an array" unless paths.is_a?(Array)
       raise ArgumentError, "paths cannot be empty" if paths.empty?
       raise ArgumentError, "timeout must be nil or a positive number" if timeout && (!timeout.is_a?(Numeric) || timeout <= 0)

       wait_for_threads(t)
       promises = []

       # Create matchers for each path
       @matcher_mut.synchronize do
         paths.each do |path|
           ge = CueEvent.new(t, p, i, d, b, m, path, [])
           prom = Promise.new
           @event_matchers.put(ge, val_matcher, i, prom)
           promises << prom
         end
       end

       # Wait for the first promise to be delivered
       start_time = Time.now
       delivered_promise = nil
       loop do
         promises.each do |prom|
           if prom.delivered?
             delivered_promise = prom
             break
           end
         end
         break if delivered_promise

         # Check timeout
         if timeout && (Time.now - start_time) > timeout
           @matcher_mut.synchronize do
             @event_matchers.prune(i)
           end
           raise Timeout::Error, "sync_first timed out after #{timeout} seconds"
         end

         sleep 0.001
       end

       # Clean up matchers
       @matcher_mut.synchronize do
         @event_matchers.prune(i)
       end

       # Find which path was triggered by checking each path
       paths.each do |path|
         res = get_w_mutex(CueEvent.new(t, p, i, d, b, m, path, []), val_matcher, true)
         return res if res
       end

       raise "sync_first error - no matching event found"
     end

     # Wait for all cues to arrive (after the current time).
     #
     # This method blocks until all specified paths have received events.
     # It returns the event with the latest timestamp among all received events.
     #
     # @param t [Numeric] Time parameter
     # @param p [Numeric] Priority parameter
     # @param i [ThreadId] Thread identifier
     # @param d [Numeric] Delta parameter
     # @param b [Numeric] Beat parameter
     # @param m [Numeric] BPM parameter
     # @param paths [Array<String>] Array of paths to wait for
     # @param val_matcher [Proc, nil] Optional value matcher lambda
     # @param timeout [Numeric, nil] Timeout in seconds, or nil for no timeout
     # @return [CueEvent] The event with the latest timestamp
     # @raise [ArgumentError] If paths is invalid or timeout is invalid
     # @raise [Timeout::Error] If timeout expires before all events arrive
     # @raise [RuntimeError] If no matching events are found after synchronization
     def sync_all(t, p, i, d, b, m, paths, val_matcher, timeout=nil)
       # Defensive programming: validate inputs
       raise ArgumentError, "paths must be an array" unless paths.is_a?(Array)
       raise ArgumentError, "paths cannot be empty" if paths.empty?
       raise ArgumentError, "timeout must be nil or a positive number" if timeout && (!timeout.is_a?(Numeric) || timeout <= 0)

       wait_for_threads(t)
       promises = []

       # Create matchers for each path
       @matcher_mut.synchronize do
         paths.each do |path|
           ge = CueEvent.new(t, p, i, d, b, m, path, [])
           prom = Promise.new
           @event_matchers.put(ge, val_matcher, i, prom)
           promises << prom
         end
       end

       # Wait for all promises to be delivered
       start_time = Time.now
       loop do
         delivered_count = promises.count(&:delivered?)
         break if delivered_count == promises.size

         # Check timeout
         if timeout && (Time.now - start_time) > timeout
           @matcher_mut.synchronize do
             @event_matchers.prune(i)
           end
           raise Timeout::Error, "sync_all timed out after #{timeout} seconds"
         end

         sleep 0.001
       end

       # Clean up matchers
       @matcher_mut.synchronize do
         @event_matchers.prune(i)
       end

       # Get the actual events for all paths
       results = []
       paths.each do |path|
         res = get_w_mutex(CueEvent.new(t, p, i, d, b, m, path, []), val_matcher, true)
         results << res if res
       end

       if results.empty?
         raise "sync_all error - no matching events found"
       end

       # Return the last result (time of last cue)
       results.max_by(&:time)
     end

     def prune(thread_id)
       # Defensive: validate input
       raise ArgumentError, "thread_id cannot be nil" if thread_id.nil?

       @get_mut.synchronize do
         @event_matchers.prune(thread_id)
       end
     end

    @@split_path_cache = Hash.new
    private
    def get_w_mutex(ge, val_matcher, get_next=false)
      # get value or return default
      if ge.path.start_with? '/'
        if ge.path.include?('/**/**')
          path = String.new(ge.path)  # multiple sequential ** matchers
        else
          path = ge.path
        end
      else
        path = String.new("/#{ge.path}")
      end

      # Remove multiple sequential ** matchers
      path.gsub!(/(\/\*\*)+/, '/**') if ge.path.include?('/**/**')

      split_path = @@split_path_cache.fetch(path) do |k|
        @@split_path_cache[path] = path.split('/').drop(1).map do |segment|
          stripped = segment.strip
          if stripped == '**'
            stripped
          elsif matcher?(segment)
            segment = Regexp.escape(segment)
            segment.gsub!('\*', '.*')
            segment.gsub!(/\\\{(.*)\\\}/, '(\1)')
            segment.gsub!(',', '|')
            segment.gsub!('\?', '.')
            segment.gsub!(/\\\[([^!].*)\\\]/, '[\1]')
            segment.gsub!(/\\\[!(.*)\\\]/, '[^\1]')
            segment.gsub!('\-', '-')
            begin
              Regexp.new(/\A#{segment}\Z/)
            rescue
              stripped
            end
          else
            stripped
          end
        end
      end
      @process_mut.synchronize do
        return __get(ge, split_path, 0, val_matcher, @state, nil, get_next)
      end

    end

    def __get(ge, split_path, idx, val_matcher, sn, res, get_next)
       # Defensive: prevent infinite recursion
       raise RuntimeError, "Maximum path depth exceeded" if idx > 1000

       if idx == split_path.size
         # we are at the leaf node
         # see if we can find a result!
         if get_next
           return find_next_event(ge, val_matcher, sn.events)
         else
           return find_most_recent_event(ge, val_matcher, sn.events)
         end
       end

       # abort early if we know there's nothing good at this
       # node or in its children
       path_segment = split_path[idx]
       return res unless path_segment
       if path_segment.is_a?(Regexp)
         sn.children.each do |k, v|
           if path_segment.match(k)
             res2 = __get(ge, split_path, idx+1, val_matcher, v, res, get_next)
             if res2
               if res
                 if get_next
                   res = res2 if res2 < res
                 else
                   res = res2 if res2 > res
                 end
               else
                 res = res2
               end
             end
           end
         end
       elsif path_segment == '**'
         if split_path.size - 1 == idx
           # this is the last path_segment
           # search through all remaining ancestors for the
           # first logically timed event

           if get_next
             return next_ancestor_event(ge, val_matcher, sn, res)
           else
             return most_recent_ancestor_event(ge, val_matcher, sn, res)
           end
         else
           # if there is a next path segment then do a search
           # through all ancesters but only as far down as
           # ones with grand children matching the next segment
           # then continue as normal
           matching_ancestors(split_path[idx + 1], sn).each do |an|
             res2 = __get(ge, split_path, idx+2, val_matcher, an, res, get_next)
             if res2
               if res
                 if get_next
                   res = res2 if res2 < res
                 else
                   res = res2 if res2 > res
                 end
               else
                 res = res2
               end
             end
           end
         end
       else
         v = sn.children[path_segment]
         if v
           res2 = __get(ge, split_path, idx+1, val_matcher, v, res, get_next)
           if res2
             if res
               if get_next
                 res = res2 if res2 < res
               else
                 res = res2 if res2 > res
               end

             else
               res = res2
             end
           end
         end
       end
       return res

     end


     def __insert_event!(e, idx=0, sn=@state)
       # Defensive: validate event
       raise ArgumentError, "event cannot be nil" if e.nil?
       raise ArgumentError, "event must be a CueEvent" unless e.is_a?(CueEvent)

       if idx == e.path_size
         # we are at the leaf node

         sn.events.unshift(e)
         bubble_up_sort!(sn.events)

         # Auto-trim history Keep at least @min_history_size elements and
         # only remove elements older than @history_depth seconds ago
         # (this may be opened to tuning in the future)
         if @trim_history
           cutoff_t = (Time.now - @history_depth).to_i
           while (sn.events.size > @min_history_size) && (sn.events.last.time.to_i < cutoff_t)
             sn.events.pop
           end
         end
         return sn
       end

       # we are not at a leaf node, drill down....

       # get path segment

       path_segment = e.path_segment(idx)
       raise "Error inserting event - idx grew too large (#{idx} is bigger than #{e.path_size})" unless path_segment

       # Defensive: prevent excessively deep paths
       raise RuntimeError, "Maximum path depth exceeded during insertion" if idx > 1000

       # get (or create) child node

       child_node = sn.children[path_segment] ||= EventHistoryNode.new

       # insert event into the child node
       __insert_event!(e, idx + 1, child_node)
       return sn
     end

    def bubble_up_sort!(events)
      # we assume that the events list is already ordered
      # however the item at idx may not be in the correct
      # place - therefore bubble it up by swapping with
      # the preceding elements in turn until the correct
      # place is found.

      idx = 0

      while (idx < events.size - 1) && (events[idx] < events[idx + 1])
        events[idx], events[idx + 1] = events[idx + 1], events[idx]
        idx += 1
      end
    end

    def wait_for_threads(vt)
      # Time sync on all other threads checking their last write promise
      # times

      # unless @all_threads
      Kernel.sleep 0.001
      return true
    end

    def matching_ancestors(partial, n, res=[])
      matcher = partial.is_a? Regexp
      n.children.each do |k, v|
        if matcher
          res << v if partial.match(k)
        else
          res << v if partial == k
        end

        matching_ancestors(partial, v, res)
      end
      return res
    end


    def most_recent_ancestor_event(ge, val_matcher, n, res)
      n.children.values.each do |c|
        candidate = find_most_recent_event(ge, val_matcher, c.events)
        if candidate
          if res
            res = candidate if candidate > res
          else
            res = candidate
          end
        end

        ancestor_candidate = most_recent_ancestor_event(ge, val_matcher, c, res)
        if ancestor_candidate
          if res
            res = ancestor_candidate if ancestor_candidate > res
          else
            res = ancestor_candidate
          end
        end
      end
      return res
    end

    def next_ancestor_event(ge, val_matcher, n, res)
      n.children.values.each do |c|
        candidate = find_next_event(ge, val_matcher, c.events)
        if candidate
          if res
            res = candidate if candidate < res
          else
            res = candidate
          end
        end

        ancestor_candidate = next_ancestor_event(ge, val_matcher, c, res)
        if ancestor_candidate
          if res
            res = ancestor_candidate if ancestor_candidate < res
          else
            res = ancestor_candidate
          end
        end
      end
      return res
    end

    def find_most_recent_event(ge, val_matcher, events)
      if val_matcher
        events.find { |e|  e <= ge  && safe_matcher_call(val_matcher, e.val) }
      else
        events.find { |e|  e <= ge }
      end
    end

    def find_next_event(ge, val_matcher, events)
      return nil if events.empty?

      # events are ordered with events[0] > events[max] later events are
      # therefore closer to the start of the list

      # Find the first match where time is greater than time t, d events
      # are ordered largest t ... smallest t so actually find the first
      # match where event's time is same or lt t, d
      #
      # Additionally if val_matcher is not nil, it is assumed to be a
      # lambda representing an arg matching fn. This will then be used
      # asqo a constraint over the val when finding a given event.

      # Find the first event that's less than the time t, d.

      idx = events.find_index { |e| e <= ge }
      if idx && idx > 0
        return events[idx - 1] unless val_matcher
        while idx > 0
          idx -= 1
          return events[idx] if safe_matcher_call(val_matcher, events[idx].val)
        end
      end

      last = events.last
      if val_matcher
        return last if last && (last > ge) && safe_matcher_call(val_matcher, last.val)
      else
        return last if last && (last > ge)
      end
      return nil
    end

    def matcher?(p)
      p.include?('*') || p.include?('{') || p.include?('?') || p.include?('[')
    end
  end
end
