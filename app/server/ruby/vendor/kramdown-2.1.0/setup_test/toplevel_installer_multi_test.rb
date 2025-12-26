#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'test_helper'

# Test suite for ToplevelInstallerMulti class
class ToplevelInstallerMultiTest < Minitest::Test
  def setup
    @temp_dir = create_temp_dir
    @packages_dir = File.join(@temp_dir, 'packages')
    FileUtils.mkdir_p(@packages_dir)

    # Create mock packages
    @package1_dir = File.join(@packages_dir, 'package1')
    @package2_dir = File.join(@packages_dir, 'package2')
    FileUtils.mkdir_p(@package1_dir)
    FileUtils.mkdir_p(@package2_dir)

    @rbconfig = mock_rbconfig
    @config_table = ConfigTable.new(@rbconfig)
    @config_table.load_multipackage_entries
    @installer = ToplevelInstallerMulti.new(@temp_dir, @config_table)
  end

  def teardown
    cleanup_temp_items(@temp_dir)
  end

  def test_initialization
    assert_instance_of ToplevelInstallerMulti, @installer
    assert_equal ['package1', 'package2'], @installer.instance_variable_get(:@packages)
    assert_instance_of Installer, @installer.instance_variable_get(:@root_installer)
  end

  def test_initialization_no_packages
    empty_dir = File.join(@temp_dir, 'empty')
    FileUtils.mkdir_p(empty_dir)

    assert_raises(RuntimeError) { ToplevelInstallerMulti.new(empty_dir, @config_table) }
  end

  def test_packages
    assert_equal ['package1', 'package2'], @installer.packages
  end

  def test_packages_setter_valid
    @installer.packages = ['package1']

    assert_equal ['package1'], @installer.packages
  end

  def test_packages_setter_empty
    assert_raises(RuntimeError) { @installer.packages = [] }
  end

  def test_packages_setter_invalid_package
    assert_raises(RuntimeError) { @installer.packages = ['nonexistent'] }
  end

  def test_run_metaconfigs
    # Create metaconfig files
    root_metaconfig = File.join(@temp_dir, 'metaconfig')
    File.write(root_metaconfig, <<~RUBY)
      add_path_config 'root_config', '/root', 'Root config'
    RUBY

    package1_metaconfig = File.join(@package1_dir, 'metaconfig')
    File.write(package1_metaconfig, <<~RUBY)
      add_path_config 'package1_config', '/package1', 'Package1 config'
    RUBY

    @installer.run_metaconfigs

    assert @config_table.key?('root_config')
    assert @config_table.key?('package1_config')
  end

  def test_init_installers
    @installer.init_installers

    installers = @installer.instance_variable_get(:@installers)
    assert_instance_of Hash, installers
    assert installers.key?('package1')
    assert installers.key?('package2')
    assert_instance_of Installer, installers['package1']
  end

  def test_extract_selection_with_list
    @installer.init_installers

    result = @installer.extract_selection('package1,package2')

    assert_equal ['package1', 'package2'], result
  end

  def test_extract_selection_invalid_package
    @installer.init_installers

    assert_raises(SetupError) { @installer.extract_selection('nonexistent') }
  end

  def test_print_usage
    @installer.init_installers

    output = StringIO.new
    @installer.print_usage(output)

    usage = output.string
    assert_match(/Included packages:/, usage)
    assert_match(/package1/, usage)
    assert_match(/package2/, usage)
  end

  def test_each_selected_installers
    @installer.init_installers
    @installer.instance_variable_set(:@selected, ['package1'])

    executed = []
    @installer.each_selected_installers do |installer|
      executed << installer.inspect
    end

    assert_equal 1, executed.size
    assert_match(/package1/, executed.first)
  end

  def test_run_hook
    # Mock root installer with run_hook method
    mock_root_installer = Minitest::Mock.new
    mock_root_installer.expect(:run_hook, nil, ['test-hook'])
    @installer.instance_variable_set(:@root_installer, mock_root_installer)

    @installer.run_hook('test-hook')

    mock_root_installer.verify
  end

  def test_verbose?
    assert @installer.verbose?

    @config_table.verbose = false
    refute @installer.verbose?
  end

  def test_no_harm?
    refute @installer.no_harm?

    @config_table.no_harm = true
    assert @installer.no_harm?
  end
end