# Euclidean Rhythm Examples for Trevosonic Pie
#
# Euclidean rhythms distribute beats evenly across steps,
# creating musically interesting patterns found across cultures.
#
# Pattern notation: sample(beats, steps, rotation)
# - beats: number of hits
# - steps: total number of steps
# - rotation: offset (optional, default 0)

# Note: Pattern notation is planned for v0.2.0+
# These examples show the intended syntax.

# Example 1: Tresillo pattern (3 over 8)
# Common in Latin music
# Future pattern way:
# live_loop :tresillo do
#   play_pattern("bd(3,8)")
# end

# Traditional Sonic Pi equivalent:
# Binary: 10010010
live_loop :tresillo_traditional do
  sample :bd_haus
  sleep 0.125
  sleep 0.125
  sample :bd_haus
  sleep 0.125
  sleep 0.125
  sample :bd_haus
  sleep 0.125
  sleep 0.125
  sleep 0.125
  sleep 0.125
end

# Example 2: Cinquillo pattern (5 over 8)
# Future pattern way:
# live_loop :cinquillo do
#   play_pattern("sn(5,8)")
# end

# Example 3: Common kick/snare with Euclidean rhythms
# Future pattern way:
# live_loop :euclidean_drums do
#   stack(
#     pattern("bd(4,16)"),      # Kick on 4s
#     pattern("sn(5,16,2)"),    # Snare offset by 2
#     pattern("hh(7,16)")       # Hi-hat pattern
#   )
# end

# Example 4: Polyrhythmic layers
# Future pattern way:
# live_loop :polyrhythm do
#   stack(
#     pattern("bd(3,8)", amp: 1.0),
#     pattern("sn(5,8)", amp: 0.8),
#     pattern("hh(7,8)", amp: 0.6)
#   )
# end

# Example 5: Melodic Euclidean patterns
# Future pattern way:
# live_loop :euclidean_melody do
#   play_pattern("c4(5,8) e4(3,8) g4(7,8)", synth: :saw)
# end

# Example 6: Combining Euclidean with other notation
# Future pattern way:
# live_loop :combined do
#   play_pattern("bd(3,8) [sn ~ sn ~] hh*4")
# end

# Example 7: African bell patterns
# Future pattern way:
# live_loop :african_bell do
#   play_pattern("perc(12,16)", synth: :sine, amp: 0.5, release: 0.1)
# end

# Example 8: Rotating Euclidean rhythms
# Future pattern way:
# live_loop :rotating do
#   4.times do |i|
#     play_pattern("bd(3,8,#{i})")
#     sleep 2
#   end
# end

# Common Euclidean patterns across cultures:
# (3,8) - Tresillo: Cuba, Brazil, Ghana
# (5,8) - Cinquillo: Cuba, Puerto Rico
# (7,8) - Bendir: Morocco
# (5,12) - Venda: South Africa
# (7,16) - Samba: Brazil
# (9,16) - Aksak: Turkey, Balkans

puts "Euclidean rhythm examples loaded."
puts "Pattern notation with Euclidean rhythms planned for v0.3.0+"
puts "See PATTERNS.md for full documentation."
