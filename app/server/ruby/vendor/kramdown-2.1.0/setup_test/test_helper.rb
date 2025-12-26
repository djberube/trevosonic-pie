#!/usr/bin/env ruby
# frozen_string_literal: true

# Test helper for setup.rb tests
# Following Durable Programming LLC testing standards

require 'minitest/autorun'
require 'minitest/pride'
require 'tempfile'
require 'fileutils'

# Load the setup.rb file to test
require_relative '../setup.rb'

module SetupTestHelper
  # Create a temporary directory for testing
  def create_temp_dir
    Dir.mktmpdir('setup_test_')
  end

  # Create a mock rbconfig for testing
  def mock_rbconfig
    {
      'prefix' => '/usr/local',
      'bindir' => '/usr/local/bin',
      'libdir' => '/usr/local/lib',
      'datadir' => '/usr/local/share',
      'mandir' => '/usr/local/share/man',
      'sysconfdir' => '/usr/local/etc',
      'localstatedir' => '/usr/local/var',
      'rubylibdir' => '/usr/local/lib/ruby/2.7.0',
      'archdir' => '/usr/local/lib/ruby/2.7.0/x86_64-linux',
      'sitedir' => '/usr/local/lib/ruby/site_ruby',
      'sitelibdir' => '/usr/local/lib/ruby/site_ruby/2.7.0',
      'sitearchdir' => '/usr/local/lib/ruby/site_ruby/2.7.0/x86_64-linux',
      'ruby_install_name' => 'ruby',
      'EXEEXT' => '',
      'MAJOR' => '2',
      'MINOR' => '7',
      'TEENY' => '0',
      'configure_args' => '',
      'DLEXT' => 'so'
    }
  end

  # Mock the RbConfig module
  def with_mock_rbconfig(rbconfig = nil)
    rbconfig ||= mock_rbconfig
    original_rbconfig = ::RbConfig::CONFIG if defined?(::RbConfig::CONFIG)
    ::RbConfig.const_set(:CONFIG, rbconfig) unless defined?(::RbConfig::CONFIG)
    yield
  ensure
    ::RbConfig.const_set(:CONFIG, original_rbconfig) if original_rbconfig
  end

  # Create a temporary file with content
  def create_temp_file(content = '', basename = 'temp')
    file = Tempfile.new(basename)
    file.write(content)
    file.close
    file.path
  end

  # Clean up temporary files/directories
  def cleanup_temp_items(*items)
    items.each do |item|
      FileUtils.rm_rf(item) if File.exist?(item)
    end
  end
end

# Include helper methods in all test classes
class Minitest::Test
  include SetupTestHelper
end