# sonicpi-lang

DSL and runtime engine for Sonic Pi / Trevosonic Pie live coding.

## Overview

`sonicpi-lang` provides the complete Domain Specific Language (DSL) and runtime infrastructure for executing Sonic Pi code. It builds on `sonicpi-core` to provide all user-facing functions like `play`, `sample`, `live_loop`, `with_fx`, and the thread/job execution runtime.

## Features

- **Core DSL**: `live_loop`, `sleep`, `sync`, `cue`, control flow
- **Sound DSL**: `play`, `sample`, `use_synth`, `with_fx`, parameter control
- **MIDI DSL**: `midi`, MIDI controller integration
- **Western Theory DSL**: Music theory helper functions
- **Runtime Engine**: Job execution, thread management, lifecycle hooks
- **Live Loop Infrastructure**: Concurrent live loop execution with timing
- **Time Management**: Beats, BPM, density, sleep
- **Preparser**: Code preprocessing before evaluation

## Installation

Add to your Gemfile:

```ruby
gem 'sonicpi-lang'
```

Or install:

```bash
gem install sonicpi-lang
```

## Usage

### Creating a Runtime

```ruby
require 'sonicpi-lang'

# Create runtime instance
runtime = SonicPi::Lang.create_runtime(
  user_methods: [],  # Custom user methods
  debug_mode: false
)

# Initialize runtime
runtime.init

# Execute code
code = <<~CODE
  play :c4
  sleep 0.5
  play :e4
CODE

runtime.run_code(code)
```

### Using DSL Functions

```ruby
require 'sonicpi-lang'

# Include DSL in your context
class MyLiveCoder
  include SonicPi::Lang::Core
  include SonicPi::Lang::Sound

  def initialize
    # Setup runtime context
  end

  def perform
    live_loop :melody do
      play scale(:c4, :major).choose
      sleep 0.25
    end

    live_loop :bass do
      use_synth :tb303
      play :c2, release: 0.5
      sleep 0.5
    end
  end
end
```

### Pattern-Based Coding

```ruby
require 'sonicpi-lang'

runtime = SonicPi::Lang.create_runtime
runtime.init

code = <<~CODE
  live_loop :drums do
    sample :bd_haus
    sleep 0.5
  end

  live_loop :melody do
    use_synth :prophet
    play_pattern_timed scale(:e3, :minor_pentatonic), 0.125
  end
CODE

runtime.run_code(code)
```

### Advanced Features

```ruby
require 'sonicpi-lang'

runtime = SonicPi::Lang.create_runtime

# Execute code with metadata
runtime.run_code(
  "play :c4",
  workspace: :ws1,
  line: 1,
  id: "unique-job-id"
)

# Stop specific workspace
runtime.stop_workspace(:ws1)

# Stop all running code
runtime.stop_all_jobs

# Shutdown runtime
runtime.shutdown
```

## Architecture

### DSL Modules

- **Core** (`lang/core.rb`): Live loops, timing, control flow, synchronization
- **Sound** (`lang/sound.rb`): Play, sample, synth control, FX
- **MIDI** (`lang/midi.rb`): MIDI I/O and control
- **Western Theory** (`lang/western_theory.rb`): Music theory helpers
- **Maths** (`lang/maths.rb`): Mathematical utilities

### Runtime Components

- **Runtime** (`runtime.rb`): Main execution engine
- **Jobs** (`jobs.rb`): Job registry and lifecycle
- **Preparser** (`preparser.rb`): Code preprocessing

### Execution Flow

```
User Code
    ↓
Preparser (optional preprocessing)
    ↓
Runtime.run_code
    ↓
Job Creation & Thread Management
    ↓
DSL Evaluation (play, sample, etc.)
    ↓
Core Library (sonicpi-core)
    ↓
SuperCollider (scsynth)
    ↓
Audio Output
```

## Use Cases

- **Custom REPLs**: Build terminal or web-based REPLs
- **Alternative Editors**: VSCode, Vim, Emacs integration
- **Language Servers**: LSP implementation for autocomplete/linting
- **Notebooks**: Jupyter-style interactive notebooks
- **Automated Composition**: Scripted music generation
- **Testing**: Unit test musical algorithms

## Requirements

- Ruby >= 2.6.0
- sonicpi-core gem
- SuperCollider (scsynth) for audio playback
- ruby-beautify, memoist gems

## Development

```bash
bundle install
bundle exec rake test
```

## API Reference

### Main Classes

- `SonicPi::Runtime`: Execution engine
- `SonicPi::Lang::Core`: Core DSL module
- `SonicPi::Lang::Sound`: Sound DSL module
- `SonicPi::Lang::MIDI`: MIDI DSL module
- `SonicPi::Jobs`: Job management

### Key Methods

#### Runtime

- `run_code(code, opts = {})`: Execute Sonic Pi code
- `stop_workspace(workspace)`: Stop specific workspace
- `stop_all_jobs`: Stop all running jobs
- `shutdown`: Clean shutdown of runtime

#### Core DSL

- `live_loop(name, opts = {}, &block)`: Define live loop
- `sleep(time)`: Sleep for duration
- `sync(cue_id)`: Wait for cue
- `cue(cue_id, *args)`: Send cue
- `tick`: Increment counter
- `look`: Read counter without incrementing

#### Sound DSL

- `play(note, opts = {})`: Play note
- `sample(name, opts = {})`: Trigger sample
- `use_synth(synth_name)`: Set current synth
- `with_fx(fx_name, opts = {}, &block)`: Apply FX
- `at(times, &block)`: Schedule block execution

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE.md

## Attribution

sonicpi-lang is extracted from Sonic Pi by Sam Aaron and contributors.
Trevosonic Pie enhancements by David Berube.

- **Sonic Pi**: https://sonic-pi.net
- **Trevosonic Pie**: https://github.com/davidjberube/trevosonic-pie

## Related Gems

- `sonicpi-core`: Core music synthesis engine
- `sonicpi-repl`: Command-line REPL
- `sonic-pi`: Full IDE distribution

## Support

- Issues: https://github.com/davidjberube/trevosonic-pie/issues
- Upstream: https://github.com/davidjberube/trevosonic-pie
