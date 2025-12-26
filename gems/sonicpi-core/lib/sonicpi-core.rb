# frozen_string_literal: true

# sonicpi-core: Core music synthesis engine for Sonic Pi / Trevosonic Pie
#
# This file provides the main entry point for the sonicpi-core gem.
# It loads core music theory, OSC protocol, and audio management components.

require_relative 'sonicpi/version'
require_relative 'sonicpi/paths'
require_relative 'sonicpi/util'

# Music Theory
require_relative 'sonicpi/note'
require_relative 'sonicpi/scale'
require_relative 'sonicpi/chord'
require_relative 'sonicpi/tuning'
require_relative 'sonicpi/pattern'
require_relative 'sonicpi/music_theory'

# OSC Protocol
require_relative 'sonicpi/osc/osc_types'
require_relative 'sonicpi/osc/oscencode'
require_relative 'sonicpi/osc/oscdecode'
require_relative 'sonicpi/osc/udp_client'
require_relative 'sonicpi/osc/udp_server'
require_relative 'sonicpi/osc/osc'

# Audio Graph
require_relative 'sonicpi/node'
require_relative 'sonicpi/synthnode'
require_relative 'sonicpi/group'
require_relative 'sonicpi/chordgroup'
require_relative 'sonicpi/chainnode'
require_relative 'sonicpi/fxnode'
require_relative 'sonicpi/blanknode'
require_relative 'sonicpi/lazynode'

# Bus Allocation
require_relative 'sonicpi/bus'
require_relative 'sonicpi/audiobus'
require_relative 'sonicpi/controlbus'
require_relative 'sonicpi/allocator'
require_relative 'sonicpi/busallocator'
require_relative 'sonicpi/audiobusallocator'
require_relative 'sonicpi/controlbusallocator'

# Buffer Management
require_relative 'sonicpi/buffer'
require_relative 'sonicpi/samplebuffer'
require_relative 'sonicpi/lazybuffer'
require_relative 'sonicpi/bufferstream'

# SuperCollider Communication
require_relative 'sonicpi/server'
require_relative 'sonicpi/studio'
require_relative 'sonicpi/scsynthexternal'

# Utilities
require_relative 'sonicpi/promise'
require_relative 'sonicpi/counter'
require_relative 'sonicpi/atom'
require_relative 'sonicpi/sox'
require_relative 'sonicpi/thread_id'
require_relative 'sonicpi/config/settings'

module SonicPi
  module Core
    VERSION = SonicPi::Version.get_version

    # Initialize core components with default configuration
    def self.init(config = {})
      # Configuration handled by individual components
      # This method exists for future initialization needs
      true
    end
  end
end
