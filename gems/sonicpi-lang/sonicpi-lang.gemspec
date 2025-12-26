# frozen_string_literal: true

require_relative '../sonicpi-core/lib/sonicpi/version'

Gem::Specification.new do |spec|
  spec.name = 'sonicpi-lang'
  spec.version = SonicPi::Version.get_version
  spec.authors = ['Sam Aaron', 'David Berube']
  spec.email = ['samaaron@gmail.com']

  spec.summary = 'DSL and runtime for Sonic Pi / Trevosonic Pie live coding'
  spec.description = <<~DESC
    sonicpi-lang provides the Domain Specific Language (DSL) and runtime engine
    for Sonic Pi and Trevosonic Pie. It includes all user-facing functions like
    play, sample, live_loop, with_fx, and the job execution runtime.

    This gem enables:
    - Custom REPLs and editors
    - Alternative frontends
    - Headless music generation
    - Language servers (LSP)
    - Notebooks and interactive environments
  DESC
  spec.homepage = 'https://github.com/davidjberube/trevosonic-pie'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/dev/CHANGELOG.md"

  spec.files = Dir.glob('{lib,spec}/**/*') + %w[
    README.md
  ]

  spec.bindir = 'bin'
  spec.executables = []
  spec.require_paths = ['lib']

  # Core dependency
  spec.add_dependency 'sonicpi-core', SonicPi::Version.get_version

  # DSL dependencies
  spec.add_dependency 'ruby-beautify', '~> 0.97'
  spec.add_dependency 'memoist', '~> 0.16'

  # Development dependencies
  spec.add_development_dependency 'minitest', '~> 5.16'
  spec.add_development_dependency 'mocha', '~> 1.1'
  spec.add_development_dependency 'rake', '~> 13.0'
end
