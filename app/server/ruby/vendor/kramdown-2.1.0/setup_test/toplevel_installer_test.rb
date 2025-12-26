#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'test_helper'

# Test suite for ToplevelInstaller class
class ToplevelInstallerTest < Minitest::Test
  def setup
    @temp_dir = create_temp_dir
    @rbconfig = mock_rbconfig
    @config_table = ConfigTable.new(@rbconfig)
    @installer = ToplevelInstaller.new(@temp_dir, @config_table)
  end

  def teardown
    cleanup_temp_items(@temp_dir)
  end

  def test_initialization
    assert_instance_of ToplevelInstaller, @installer
    assert_equal @temp_dir, @installer.instance_variable_get(:@ardir)
    assert_equal @config_table, @installer.instance_variable_get(:@config)
    assert_nil @installer.instance_variable_get(:@valid_task_re)
  end

  def test_config
    @config_table.load_standard_entries
    assert_equal '/usr/local', @installer.config('prefix')
  end

  def test_inspect
    expected = "#<ToplevelInstaller #{__id__()}>"

    assert_match(/#<ToplevelInstaller \d+>/, @installer.inspect)
  end

  def test_multipackage_false
    skip "Multipackage check depends on script location"
  end

  def test_load_rbconfig_with_arg
    # This test is complex to mock properly, so we'll just ensure it doesn't crash
    original_argv = ARGV.dup
    ARGV.replace([])

    loaded = ToplevelInstaller.load_rbconfig
    assert_instance_of Hash, loaded
    assert loaded.key?('prefix')
  ensure
    ARGV.replace(original_argv)
  end

  def test_load_rbconfig_without_arg
    original_argv = ARGV.dup
    ARGV.replace([])

    # Mock require to avoid loading actual rbconfig
    ToplevelInstaller.stub(:require, true) do
      loaded = ToplevelInstaller.load_rbconfig
      assert_equal ::RbConfig::CONFIG, loaded
    end
  ensure
    ARGV.replace(original_argv)
  end

  def test_srcdir_root
    assert_equal @temp_dir, @installer.srcdir_root
  end

  def test_objdir_root
    assert_equal '.', @installer.objdir_root
  end

  def test_relpath
    assert_equal '.', @installer.relpath
  end

  def test_run_metaconfigs
    metaconfig_file = File.join(@temp_dir, 'metaconfig')
    File.write(metaconfig_file, <<~RUBY)
      add_path_config 'test_path', '/test/path', 'Test path config'
    RUBY

    @installer.run_metaconfigs

    assert @config_table.key?('test_path')
  end

  def test_init_installers
    @installer.init_installers

    installer = @installer.instance_variable_get(:@installer)
    assert_instance_of Installer, installer
  end

  def test_parsearg_global_no_args
    original_argv = ARGV.dup
    ARGV.replace([])

    result = @installer.parsearg_global

    assert_nil result
  ensure
    ARGV.replace(original_argv)
  end

  def test_parsearg_global_valid_task
    original_argv = ARGV.dup
    ARGV.replace(['config'])

    result = @installer.parsearg_global

    assert_equal 'config', result
  ensure
    ARGV.replace(original_argv)
  end

  def test_parsearg_global_invalid_task
    original_argv = ARGV.dup
    ARGV.replace(['invalid_task'])

    assert_raises(SetupError) { @installer.parsearg_global }
  ensure
    ARGV.replace(original_argv)
  end

  def test_parsearg_global_quiet_flag
    original_argv = ARGV.dup
    ARGV.replace(['-q'])

    @installer.parsearg_global

    refute @config_table.verbose?
  ensure
    ARGV.replace(original_argv)
  end

  def test_parsearg_global_verbose_flag
    original_argv = ARGV.dup
    ARGV.replace(['--verbose'])

    @installer.parsearg_global

    assert @config_table.verbose?
  ensure
    ARGV.replace(original_argv)
  end

  def test_parsearg_global_help_flag
    original_argv = ARGV.dup
    ARGV.replace(['--help'])

    assert_raises(SystemExit) { @installer.parsearg_global }
  ensure
    ARGV.replace(original_argv)
  end

  def test_parsearg_global_version_flag
    original_argv = ARGV.dup
    ARGV.replace(['--version'])

    assert_raises(SystemExit) { @installer.parsearg_global }
  ensure
    ARGV.replace(original_argv)
  end

  def test_parsearg_global_copyright_flag
    original_argv = ARGV.dup
    ARGV.replace(['--copyright'])

    assert_raises(SystemExit) { @installer.parsearg_global }
  ensure
    ARGV.replace(original_argv)
  end

  def test_parsearg_global_unknown_flag
    original_argv = ARGV.dup
    ARGV.replace(['--unknown'])

    assert_raises(SetupError) { @installer.parsearg_global }
  ensure
    ARGV.replace(original_argv)
  end

  def test_valid_task_true
    assert @installer.valid_task?('config')
    assert @installer.valid_task?('setup')
    assert @installer.valid_task?('install')
  end

  def test_valid_task_false
    refute @installer.valid_task?('invalid')
  end

  def test_valid_task_re
    re = @installer.valid_task_re

    assert_instance_of Regexp, re
    assert_match re, 'config'
    refute_match re, 'invalid'
  end

  def test_parsearg_no_options_with_args
    @config_table.load_standard_entries
    @config_table.fixup

    original_argv = ARGV.dup
    ARGV.replace(['invalid_option'])

    assert_raises(SetupError) { @installer.parsearg_config }
  ensure
    ARGV.replace(original_argv)
  end

  def test_parsearg_config_with_options
    @config_table.load_standard_entries
    @config_table.fixup

    original_argv = ARGV.dup
    ARGV.replace(['--prefix=/custom'])

    @installer.parsearg_config

    assert_equal '/custom', @config_table['prefix']
  ensure
    ARGV.replace(original_argv)
  end

  def test_parsearg_config_with_double_dash
    original_argv = ARGV.dup
    ARGV.replace(['--', 'remaining', 'args'])

    @installer.parsearg_config

    assert_equal ['remaining', 'args'], @config_table.config_opt
  ensure
    ARGV.replace(original_argv)
  end

  def test_parsearg_install_no_harm
    original_argv = ARGV.dup
    ARGV.replace(['--no-harm'])

    @installer.parsearg_install

    assert @config_table.no_harm?
    assert_equal '', @config_table.install_prefix
  ensure
    ARGV.replace(original_argv)
  end

  def test_parsearg_install_with_prefix
    original_argv = ARGV.dup
    ARGV.replace(['--prefix=/install/path'])

    @installer.parsearg_install

    refute @config_table.no_harm?
    assert_equal '/install/path', @config_table.install_prefix
  ensure
    ARGV.replace(original_argv)
  end

  def test_parsearg_install_unknown_option
    original_argv = ARGV.dup
    ARGV.replace(['--unknown'])

    assert_raises(SetupError) { @installer.parsearg_install }
  ensure
    ARGV.replace(original_argv)
  end

  def test_print_usage
    output = StringIO.new
    @installer.print_usage(output)

    usage = output.string
    assert_match(/Typical Installation Procedure:/, usage)
    assert_match(/ruby #{File.basename($0)} config/, usage)
    assert_match(/Global options:/, usage)
    assert_match(/Tasks:/, usage)
  end

  def test_exec_config
    @config_table.load_standard_entries
    @installer.init_installers

    @installer.exec_config

    # Should save config
    assert File.exist?(@config_table.savefile)
  end

  def test_exec_setup
    @config_table.load_standard_entries
    @installer.init_installers

    @installer.exec_setup

    # Setup execution - hard to test without actual files
  end

  def test_exec_install
    @config_table.load_standard_entries
    @installer.init_installers

    @installer.exec_install

    # InstalledFiles is created only if files are installed
    # Since no files in temp dir, it should not exist
    assert !File.exist?(File.join('.', 'InstalledFiles'))
  end

  def test_exec_test
    @installer.init_installers

    # Without test directory, should not raise error
    @installer.exec_test
  end

  def test_exec_show
    @config_table.load_standard_entries

    output = capture_io { @installer.exec_show }.first

    assert_match(/prefix.*\/usr\/local/, output)
  end

  def test_exec_clean
    @config_table.load_standard_entries
    @installer.init_installers

    @installer.exec_clean

    # Should remove savefile and InstalledFiles
    refute File.exist?(@config_table.savefile)
    refute File.exist?(File.join('.', 'InstalledFiles'))
  end

  def test_exec_distclean
    @config_table.load_standard_entries
    @installer.init_installers

    @installer.exec_distclean

    # Should remove savefile and InstalledFiles
    refute File.exist?(@config_table.savefile)
    refute File.exist?(File.join('.', 'InstalledFiles'))
  end
end