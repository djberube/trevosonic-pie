# frozen_string_literal: true

require_relative 'lib/sonicpi/version'

Gem::Specification.new do |spec|
  spec.name = 'sonicpi-core'
  spec.version = SonicPi::Version.get_version
  spec.authors = ['Sam Aaron', 'David Berube']
  spec.email = ['samaaron@gmail.com']

  spec.summary = 'Core music synthesis engine for Sonic Pi / Trevosonic Pie'
  spec.description = <<~DESC
    sonicpi-core provides the core music synthesis engine for Sonic Pi and Trevosonic Pie.
    It includes music theory primitives (scales, chords, patterns), OSC protocol implementation,
    SuperCollider communication, audio graph management, and buffer/sample handling.

    This gem can be used headless without the Sonic Pi IDE for:
    - Headless music servers
    - Alternative editors and interfaces
    - Embedded systems
    - Web-based applications
    - CI/CD audio testing
  DESC
  spec.homepage = 'https://github.com/davidjberube/trevosonic-pie'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/dev/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob('{lib,spec}/**/*') + %w[
    README.md
    LICENSE.md
    CHANGELOG.md
  ]

  spec.bindir = 'bin'
  spec.executables = []
  spec.require_paths = ['lib']

  # Core dependencies
  spec.add_dependency 'concurrent-ruby', '~> 1.3'
  spec.add_dependency 'multi_json', '~> 1.15'
  spec.add_dependency 'wavefile', '~> 1.1'

  # Development dependencies
  spec.add_development_dependency 'minitest', '~> 5.16'
  spec.add_development_dependency 'mocha', '~> 1.1'
  spec.add_development_dependency 'rake', '~> 13.0'
end
