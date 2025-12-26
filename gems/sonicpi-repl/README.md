# sonicpi-repl

Command-line REPL for Sonic Pi / Trevosonic Pie.

## Overview

`sonicpi-repl` provides a terminal-based Read-Eval-Print Loop (REPL) for live coding with Sonic Pi without requiring the GUI. It manages the daemon process, handles interactive input, and executes Sonic Pi code in real-time.

## Installation

```bash
gem install sonicpi-repl
```

Or add to your Gemfile:

```ruby
gem 'sonicpi-repl'
```

## Usage

### Starting the REPL

```bash
sonicpi-repl
```

This will:
1. Start the daemon process (if not already running)
2. Launch SuperCollider (scsynth)
3. Initialize the Sonic Pi runtime
4. Open an interactive REPL session

### REPL Commands

```ruby
# Play a note
play :c4

# Create a live loop
live_loop :drums do
  sample :bd_haus
  sleep 0.5
end

# Use effects
with_fx :reverb do
  play :e4
end

# Exit REPL
exit
# or press Ctrl+D
```

### Programmatic Usage

```ruby
require 'sonicpi-repl'

# Start REPL programmatically
SonicPi::REPL.start

# Or use with custom configuration
SonicPi::REPL.start(
  daemon_port: 4558,
  spider_port: 4557,
  debug: true
)
```

## Features

- **Interactive REPL**: Real-time code execution
- **Process Management**: Automatic daemon startup/shutdown
- **Zombie Kill Switch**: Cleans up orphaned processes
- **History**: Command history with readline support
- **Headless Operation**: No GUI required
- **Tab Completion**: Autocomplete for Sonic Pi functions (if configured)

## Architecture

### Components

- **REPL** (`repl.rb`): Interactive loop, user input handling
- **Daemon** (`daemon.rb`): Process manager for scsynth, spider server, Tau
- **Runtime Integration**: Uses `sonicpi-lang` for code execution

### Process Flow

```
User Input (Terminal)
    ↓
REPL
    ↓
Daemon (Process Manager)
    ↓
Spider Server (sonicpi-lang Runtime)
    ↓
SuperCollider (scsynth)
    ↓
Audio Output
```

## Configuration

Environment variables:

- `SONIC_PI_HOME`: Base directory for Sonic Pi
- `SONIC_PI_DEBUG`: Enable debug output
- `SCSYNTH_PATH`: Path to scsynth binary

## Requirements

- Ruby >= 2.6.0
- sonicpi-lang gem (includes sonicpi-core)
- SuperCollider (scsynth) installed
- readline library (for history/completion)

## Development

```bash
bundle install
bundle exec rake test
```

## Use Cases

- **Server Deployments**: Run Sonic Pi on headless servers
- **SSH Sessions**: Live code over SSH
- **Scripting**: Automated music generation scripts
- **Education**: Terminal-based tutorials
- **CI/CD**: Automated testing of Sonic Pi code

## Examples

### Simple Beat

```bash
$ sonicpi-repl
Sonic Pi REPL v4.5.0
> live_loop :beat do
    sample :bd_haus
    sleep 0.5
  end
OK
```

### Melodic Pattern

```bash
> live_loop :melody do
    use_synth :prophet
    play scale(:e3, :minor_pentatonic).choose
    sleep 0.25
  end
OK
```

### Stop All

```bash
> stop
# All live loops stopped
```

## Limitations

- No GUI visualizations
- No inline help browser (use command-line docs)
- Limited autocomplete (depends on readline configuration)

## Troubleshooting

### REPL won't start

Check if processes are already running:

```bash
ps aux | grep sonic-pi
pkill -f sonic-pi  # Kill all Sonic Pi processes
```

### No audio output

Verify scsynth is running:

```bash
ps aux | grep scsynth
```

Check scsynth path:

```bash
which scsynth
export SCSYNTH_PATH=/path/to/scsynth
```

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

sonicpi-repl is extracted from Sonic Pi by Sam Aaron and contributors.
Trevosonic Pie enhancements by David Berube.

- **Sonic Pi**: https://sonic-pi.net
- **Trevosonic Pie**: https://github.com/davidjberube/trevosonic-pie

## Related Gems

- `sonicpi-core`: Core music synthesis engine
- `sonicpi-lang`: DSL and runtime
- `sonic-pi`: Full IDE distribution

## Support

- Issues: https://github.com/davidjberube/trevosonic-pie/issues
- Upstream: https://github.com/davidjberube/trevosonic-pie
