require 'concurrent/utility/monotonic_time'
require 'benchmark'

module Concurrent

  RSpec.describe 'monotonic_time performance' do
    let(:iterations) { 10_000 }

    context 'performance benchmarks' do
      it 'measures call performance' do
        time = Benchmark.measure do
          iterations.times { Concurrent.monotonic_time }
        end

        puts "\nMonotonic time performance (#{iterations} calls):"
        puts "Total time: #{time.total.round(4)}s"
        puts "Average time per call: #{(time.total / iterations * 1_000_000).round(2)}μs"

        # Should be very fast (< 1μs per call typically)
        expect(time.total).to be < 1.0 # 1 second for 10k calls
      end

      it 'compares different units performance' do
        units = [:float_second, :second, :millisecond, :microsecond, :nanosecond]

        results = {}
        units.each do |unit|
          time = Benchmark.measure do
            1000.times { Concurrent.monotonic_time(unit) }
          end
          results[unit] = time.total
        end

        puts "\nPerformance by unit (1000 calls each):"
        results.each do |unit, time|
          puts "#{unit}: #{time.round(4)}s (#{(time * 1_000_000).round(2)}μs per call)"
        end

        # All should be reasonably fast
        results.each_value do |time|
          expect(time).to be < 0.1 # 100ms for 1000 calls
        end
      end

      it 'measures memory allocation' do
        # Rough memory check - in practice use dedicated profiling tools
        before = ObjectSpace.count_objects

        1000.times { Concurrent.monotonic_time }

        after = ObjectSpace.count_objects

        total_allocated = (after[:TOTAL] || 0) - (before[:TOTAL] || 0)

        puts "\nMemory allocation (1000 calls): #{total_allocated} objects"

        # Should not allocate excessive objects (allowing some tolerance for test overhead)
        expect(total_allocated).to be < 5000
      end
    end

    context 'scaling performance' do
      it 'maintains performance under load' do
        # Test that performance doesn't degrade significantly with repeated calls
        times = []

        10.times do
          start = Time.now
          1000.times { Concurrent.monotonic_time }
          elapsed = Time.now - start
          times << elapsed
        end

        # Calculate coefficient of variation (should be low for consistent performance)
        mean = times.sum / times.size
        variance = times.map { |t| (t - mean) ** 2 }.sum / times.size
        std_dev = Math.sqrt(variance)
        cv = std_dev / mean

        puts "\nPerformance consistency (10 × 1000 calls):"
        puts "Mean: #{(mean * 1000).round(2)}ms"
        puts "Std Dev: #{(std_dev * 1000).round(2)}ms"
        puts "CV: #{(cv * 100).round(2)}%"

        # Coefficient of variation should be reasonable (< 20%)
        expect(cv).to be < 0.2
      end
    end

    context 'threading performance' do
      it 'performs well under thread contention' do
        thread_count = 10
        calls_per_thread = 1000

        start_time = Time.now

        threads = thread_count.times.map do
          Thread.new do
            calls_per_thread.times { Concurrent.monotonic_time }
          end
        end

        threads.each(&:join)
        total_time = Time.now - start_time

        total_calls = thread_count * calls_per_thread
        avg_time_per_call = total_time / total_calls

        puts "\nThreading performance (#{thread_count} threads × #{calls_per_thread} calls):"
        puts "Total time: #{total_time.round(4)}s"
        puts "Average time per call: #{(avg_time_per_call * 1_000_000).round(2)}μs"

        # Should still be fast even with threading
        expect(avg_time_per_call).to be < 0.001 # 1ms per call
      end
    end
  end
end