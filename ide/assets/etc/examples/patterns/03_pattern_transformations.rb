# Pattern Transformation Examples for Trevosonic Pie
#
# Demonstrates how to manipulate patterns using transformations.
# These transformations allow you to create variations without
# rewriting the entire pattern.

# Note: Pattern notation is planned for v0.2.0+
# Pattern transformations planned for v0.3.0+

# Example 1: Reversing patterns
# Future pattern way:
# live_loop :reversible do
#   base = pattern("c4 e4 g4 b4")
#
#   play_pattern(base)        # Forward
#   sleep 1
#   play_pattern(base.rev)    # Backward
#   sleep 1
# end

# Example 2: Speed transformations
# Future pattern way:
# live_loop :speed_changes do
#   base = pattern("c4 e4 g4 b4")
#
#   play_pattern(base)           # Normal speed
#   sleep 1
#   play_pattern(base.fast(2))   # Double speed
#   sleep 0.5
#   play_pattern(base.slow(2))   # Half speed
#   sleep 2
# end

# Example 3: Rotation
# Future pattern way:
# live_loop :rotating do
#   base = pattern("c4 e4 g4 b4")
#
#   4.times do |i|
#     play_pattern(base.rotate(i))
#     sleep 1
#   end
# end

# Example 4: Conditional transformations with 'every'
# Future pattern way:
# live_loop :conditional do
#   base = pattern("bd sn bd sn")
#
#   # Reverse every 4th cycle
#   play_pattern(base.every(4, :rev))
# end

# Example 5: Combining transformations
# Future pattern way:
# live_loop :combined_transforms do
#   base = pattern("c4 e4 g4 b4")
#
#   play_pattern(base.fast(2).rev.rotate(1))
# end

# Example 6: Dynamic pattern building
# Future pattern way:
# live_loop :dynamic do
#   patterns = [
#     pattern("c4 e4 g4 b4"),
#     pattern("d4 f4 a4 c5"),
#     pattern("e4 g4 b4 d5")
#   ]
#
#   # Play each pattern with different transformations
#   patterns.each_with_index do |p, i|
#     case i
#     when 0
#       play_pattern(p)
#     when 1
#       play_pattern(p.rev)
#     when 2
#       play_pattern(p.fast(2))
#     end
#     sleep 1
#   end
# end

# Example 7: Degradation (removing events randomly)
# Future pattern way:
# live_loop :degraded do
#   base = pattern("hh*8")
#
#   # Gradually degrade pattern
#   8.times do |i|
#     play_pattern(base.degrade(i * 0.1))
#     sleep 1
#   end
# end

# Example 8: Layering transformed patterns
# Future pattern way:
# live_loop :layered_transforms do
#   base = pattern("c4 e4 g4 b4")
#
#   stack(
#     pattern(base),                    # Original
#     pattern(base.fast(2), amp: 0.5),  # Faster, quieter
#     pattern(base.slow(2), octave: -1) # Slower, lower
#   )
# end

# Example 9: Pattern evolution over time
# Future pattern way:
# live_loop :evolving do
#   base = pattern("c4 e4 g4 b4")
#   cycle_count = 0
#
#   loop do
#     case cycle_count % 16
#     when 0..3
#       play_pattern(base)
#     when 4..7
#       play_pattern(base.rev)
#     when 8..11
#       play_pattern(base.fast(2))
#     when 12..15
#       play_pattern(base.rotate(cycle_count % 4))
#     end
#
#     cycle_count += 1
#     sleep 1
#   end
# end

# Example 10: Stochastic transformations
# Future pattern way:
# live_loop :stochastic do
#   base = pattern("bd sn bd sn")
#
#   transforms = [:rev, :fast, :slow, :rotate]
#
#   # Apply random transformation
#   transform = transforms.choose
#   case transform
#   when :rev
#     play_pattern(base.rev)
#   when :fast
#     play_pattern(base.fast(2))
#   when :slow
#     play_pattern(base.slow(2))
#   when :rotate
#     play_pattern(base.rotate(rand(4)))
#   end
# end

puts "Pattern transformation examples loaded."
puts "These features are planned for future Trevosonic Pie releases."
puts "Transformations allow powerful pattern manipulation without rewriting code."
