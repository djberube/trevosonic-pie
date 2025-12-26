# frozen_string_literal: true

require_relative '../sonicpi-core/lib/sonicpi/version'

Gem::Specification.new do |spec|
  spec.name = 'sonicpi-repl'
  spec.version = SonicPi::Version.get_version
  spec.authors = ['Sam Aaron', 'David Berube']
  spec.email = ['samaaron@gmail.com']

  spec.summary = 'Command-line REPL for Sonic Pi / Trevosonic Pie'
  spec.description = <<~DESC
    sonicpi-repl provides a terminal-based Read-Eval-Print Loop (REPL) for
    Sonic Pi and Trevosonic Pie. It includes process management, daemon handling,
    and interactive code execution without requiring the GUI.

    Perfect for:
    - Terminal-based live coding
    - Server deployments
    - Scripting and automation
    - Headless music generation
  DESC
  spec.homepage = 'https://github.com/davidjberube/trevosonic-pie'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/dev/CHANGELOG.md"

  spec.files = Dir.glob('{lib,bin}/**/*') + %w[
    README.md
  ]

  spec.bindir = 'bin'
  spec.executables = ['sonicpi-repl']
  spec.require_paths = ['lib']

  # Dependencies
  spec.add_dependency 'sonicpi-lang', SonicPi::Version.get_version

  # Development dependencies
  spec.add_development_dependency 'minitest', '~> 5.16'
  spec.add_development_dependency 'rake', '~> 13.0'
end
