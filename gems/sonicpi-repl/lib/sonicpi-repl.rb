# frozen_string_literal: true

# sonicpi-repl: Command-line REPL for Sonic Pi / Trevosonic Pie
#
# This file provides the main entry point for the sonicpi-repl gem.

require 'sonicpi-lang'
require_relative 'sonicpi/daemon'
require_relative 'sonicpi/repl'

module SonicPi
  module REPL
    VERSION = SonicPi::Version.get_version

    # Start the REPL with optional configuration
    # @param opts [Hash] Configuration options
    # @option opts [Integer] :daemon_port Port for daemon communication
    # @option opts [Integer] :spider_port Port for spider server
    # @option opts [Boolean] :debug Enable debug mode
    def self.start(opts = {})
      repl = SonicPi::REPLClient.new(opts)
      repl.run
    end
  end
end
