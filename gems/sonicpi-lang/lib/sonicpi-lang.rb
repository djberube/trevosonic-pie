# frozen_string_literal: true

# sonicpi-lang: DSL and runtime for Sonic Pi / Trevosonic Pie
#
# This file provides the main entry point for the sonicpi-lang gem.
# It loads the core library and all DSL modules.

require 'sonicpi-core'

# Thread management
require_relative 'sonicpi/thread_id'
require_relative 'sonicpi/sthread'

# Event system
require_relative 'sonicpi/cueevent'
require_relative 'sonicpi/event_history'
require_relative 'sonicpi/incomingevents'

# Lifecycle
require_relative 'sonicpi/lifecyclehooks'

# Runtime and job management
require_relative 'sonicpi/preparser'
require_relative 'sonicpi/jobs'
require_relative 'sonicpi/runtime'

# DSL modules
require_relative 'sonicpi/lang/core'
require_relative 'sonicpi/lang/sound'
require_relative 'sonicpi/lang/midi'
require_relative 'sonicpi/lang/western_theory'
require_relative 'sonicpi/lang/maths'

module SonicPi
  module Lang
    VERSION = SonicPi::Version.get_version

    # Create a new runtime instance
    # @param config [Hash] Runtime configuration options
    # @return [SonicPi::Runtime] Configured runtime instance
    def self.create_runtime(config = {})
      SonicPi::Runtime.new(config)
    end
  end
end
