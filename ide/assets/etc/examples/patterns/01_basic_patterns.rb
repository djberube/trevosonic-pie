# Welcome to Trevosonic Pie Pattern Notation Examples
#
# This file demonstrates basic pattern notation concepts.
# Pattern notation provides a concise way to express musical sequences.

# Note: Pattern notation is planned for v0.2.0+
# These examples show the intended syntax and usage.

# Example 1: Simple sequence
# Traditional Sonic Pi way:
live_loop :traditional do
  play :c4
  sleep 0.25
  play :e4
  sleep 0.25
  play :g4
  sleep 0.25
  play :b4
  sleep 0.25
end

# Future pattern notation way:
# live_loop :pattern_style do
#   play_pattern("c4 e4 g4 b4")
# end

# Example 2: Patterns with rests
# Traditional way:
live_loop :with_rests do
  play :c4
  sleep 0.25
  # rest
  sleep 0.25
  play :g4
  sleep 0.25
  # rest
  sleep 0.25
end

# Future pattern way:
# live_loop :pattern_rests do
#   play_pattern("c4 ~ g4 ~")
# end

# Example 3: Chord patterns (polyphony)
# Traditional way:
live_loop :chords_traditional do
  play_chord [:c4, :e4, :g4]
  sleep 0.5
  play_chord [:d4, :f4, :a4]
  sleep 0.5
end

# Future pattern way:
# live_loop :pattern_chords do
#   play_pattern("[c4,e4,g4] [d4,f4,a4]")
# end

# Example 4: Subdivisions
# Traditional way:
live_loop :subdivisions_traditional do
  play :c4
  sleep 0.25
  play :e4
  sleep 0.125
  play :g4
  sleep 0.125
  play :b4
  sleep 0.25
end

# Future pattern way:
# live_loop :pattern_subdivisions do
#   play_pattern("c4 [e4 g4] b4")
# end

# Example 5: Drum patterns
# Traditional way:
live_loop :drums_traditional do
  sample :bd_haus
  sleep 0.25
  sample :sn_dolf
  sleep 0.25
  sample :bd_haus
  sleep 0.25
  sample :sn_dolf
  sleep 0.25
end

# Future pattern way:
# live_loop :pattern_drums do
#   play_pattern("bd sn bd sn")  # Using sample names
# end

# Example 6: Complex rhythms with subdivisions and rests
# Future pattern way:
# live_loop :complex_pattern do
#   play_pattern("bd*2 [~ sn] bd [sn ~]")
# end

# Example 7: Layering multiple patterns
# Future pattern way:
# live_loop :layered do
#   stack(
#     pattern("c2 ~ e2 ~", synth: :fm),
#     pattern("[c4,e4,g4] [d4,f4,a4]", synth: :sine),
#     pattern("bd sn bd sn")
#   )
# end

# Example 8: Pattern transformations
# Future pattern way:
# live_loop :transformed do
#   base = pattern("c4 e4 g4 b4")
#
#   # Play forward for 4 cycles
#   4.times { play_pattern(base) }
#
#   # Then play reversed for 4 cycles
#   4.times { play_pattern(base.rev) }
# end

# For now, use traditional Sonic Pi syntax.
# Pattern notation will be available in future releases!

puts "Pattern notation examples loaded."
puts "These demonstrate future features planned for Trevosonic Pie."
puts "Currently, use traditional Sonic Pi syntax for your live coding."
