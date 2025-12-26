# sonicpi-core

Core music synthesis engine for Sonic Pi / Trevosonic Pie.

## Overview

`sonicpi-core` is the foundation of the Sonic Pi live coding environment, extracted as an independent gem. It provides music theory primitives, OSC protocol implementation, SuperCollider communication, and audio graph management without requiring the Sonic Pi IDE or GUI.

## Features

- **Music Theory**: Scales, chords, notes, tunings, and pattern generation
- **OSC Protocol**: Complete OSC encoding/decoding with TCP/UDP clients and servers
- **SuperCollider Integration**: Communication with scsynth audio server
- **Audio Graph Management**: Nodes, groups, FX chains, bus allocation
- **Buffer/Sample Management**: Sample loading, caching, and streaming
- **Concurrency Primitives**: Thread-safe counters, promises, atoms
- **Configuration**: JSON-backed settings storage

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sonicpi-core'
```

Or install it yourself:

```bash
gem install sonicpi-core
```

## Usage

### Basic Scale and Chord Generation

```ruby
require 'sonicpi/scale'
require 'sonicpi/chord'

# Create a C major scale
scale = SonicPi::Scale.new(:c4, :major)
puts scale.to_a  # => [60, 62, 64, 65, 67, 69, 71, 72]

# Create a C major 7th chord
chord = SonicPi::Chord.new(:c4, :major7)
puts chord.to_a  # => [60, 64, 67, 71]
```

### Pattern Generation

```ruby
require 'sonicpi/pattern'

# Create a simple pattern
pattern = SonicPi::Pattern.new("c e g b")
events = pattern.events_for_cycle(0)

events.each do |event|
  puts "#{event.type}: #{event.value} at #{event.start}"
end
```

### Music Theory Utilities

```ruby
require 'sonicpi/music_theory'

# Calculate interval between notes
interval = SonicPi::MusicTheory.interval(:c4, :e4)  # => 4 semitones

# Voice leading
chord1 = [60, 64, 67]  # C major
chord2 = [65, 69, 72]  # F major
voiced = SonicPi::MusicTheory.voice_leading(chord1, chord2)
puts voiced  # => [65, 67, 72] (closest voicing)
```

### SuperCollider Communication

```ruby
require 'sonicpi/server'
require 'sonicpi/studio'

# Initialize studio
studio = SonicPi::Studio.new(...)
studio.boot

# Send OSC commands to scsynth
studio.trigger_synth(:beep, {note: 60, amp: 0.5})
```

## Architecture

### Core Components

- **Music Theory**: `scale.rb`, `chord.rb`, `note.rb`, `tuning.rb`, `music_theory.rb`, `pattern.rb`
- **OSC Protocol**: `osc/osc.rb`, `osc/oscencode.rb`, `osc/oscdecode.rb`, `osc/*_client.rb`, `osc/*_server.rb`
- **SuperCollider**: `server.rb`, `studio.rb`, `scsynthexternal.rb`
- **Audio Graph**: `node.rb`, `synthnode.rb`, `group.rb`, `fxnode.rb`, `chainnode.rb`
- **Bus Allocation**: `bus.rb`, `audiobus.rb`, `controlbus.rb`, `allocator.rb`, `busallocator.rb`
- **Buffers**: `buffer.rb`, `samplebuffer.rb`, `lazybuffer.rb`, `sample_loader.rb`
- **Utilities**: `util.rb`, `promise.rb`, `counter.rb`, `atom.rb`

### No Dependencies On

- Sonic Pi GUI
- REPL/runtime
- Job/thread management
- Live loop infrastructure

## Use Cases

- **Headless Servers**: Generate music without GUI (web servers, cloud functions)
- **Alternative Editors**: Build VSCode, Vim, or web-based Sonic Pi interfaces
- **Embedded Systems**: Run on Raspberry Pi Zero, IoT devices
- **Testing**: Automated music generation in CI/CD pipelines
- **Research**: Algorithmic composition and music theory exploration

## Requirements

- Ruby >= 2.6.0
- SuperCollider (scsynth) for audio playback
- concurrent-ruby, multi_json, wavefile gems

## Development

After checking out the repo:

```bash
bundle install
bundle exec rake test
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE.md

## Attribution

sonicpi-core is extracted from Sonic Pi by Sam Aaron and contributors.
Trevosonic Pie enhancements by David Berube.

- **Sonic Pi**: https://sonic-pi.net
- **Trevosonic Pie**: https://github.com/davidjberube/trevosonic-pie

## Related Gems

- `sonicpi-lang`: DSL and runtime for executing Sonic Pi code
- `sonicpi-repl`: Command-line REPL interface
- `sonic-pi`: Full IDE distribution

## Support

- Issues: https://github.com/davidjberube/trevosonic-pie/issues
- Upstream Sonic Pi: https://github.com/davidjberube/trevosonic-pie
