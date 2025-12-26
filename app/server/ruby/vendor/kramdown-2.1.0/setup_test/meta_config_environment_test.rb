#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'test_helper'

# Test suite for MetaConfigEnvironment class
class MetaConfigEnvironmentTest < Minitest::Test
  def setup
    @rbconfig = mock_rbconfig
    @config_table = ConfigTable.new(@rbconfig)
    @installer = nil # For single-package mode
    @meta_config = ConfigTable::MetaConfigEnvironment.new(@config_table, @installer)
  end

  def test_initialization
    assert_instance_of ConfigTable::MetaConfigEnvironment, @meta_config
    assert_equal @config_table, @meta_config.instance_variable_get(:@config)
    assert_nil @meta_config.instance_variable_get(:@installer)
  end

  def test_config_names
    @config_table.load_standard_entries
    names = @meta_config.config_names

    assert_includes names, 'prefix'
    assert_includes names, 'bindir'
    assert_includes names, 'rubyprog'
  end

  def test_config_key_exists
    @config_table.load_standard_entries

    assert @meta_config.config?('prefix')
    refute @meta_config.config?('nonexistent')
  end

  def test_bool_config?
    @config_table.load_standard_entries
    bool_item = ConfigTable::BoolItem.new('test_bool', 'yes/no', 'no', 'Test boolean')
    @config_table.add(bool_item)

    assert @meta_config.bool_config?('test_bool')
    refute @meta_config.bool_config?('prefix') # PathItem, not BoolItem
  end

  def test_path_config?
    @config_table.load_standard_entries

    assert @meta_config.path_config?('prefix')
    # Test with a config that exists but is not a path config
    refute @meta_config.path_config?('shebang')
  end

  def test_value_config?
    @config_table.load_standard_entries

    # Regular value config
    assert @meta_config.value_config?('prefix')

    # Exec config (non-value)
    exec_item = ConfigTable::ExecItem.new('test_exec', 'opt1/opt2', 'description') {}
    @config_table.add(exec_item)

    refute @meta_config.value_config?('test_exec')
  end

  def test_add_config
    item = ConfigTable::Item.new('custom', 'template', 'default', 'Custom config')
    @meta_config.add_config(item)

    assert @config_table.key?('custom')
    assert_equal item, @config_table.lookup('custom')
  end

  def test_add_bool_config
    @meta_config.add_bool_config('custom_bool', true, 'Custom boolean config')

    assert @config_table.key?('custom_bool')
    item = @config_table.lookup('custom_bool')
    assert_instance_of ConfigTable::BoolItem, item
    assert_equal 'yes', item.value
  end

  def test_add_bool_config_false
    @meta_config.add_bool_config('custom_bool', false, 'Custom boolean config')

    item = @config_table.lookup('custom_bool')
    assert_equal 'no', item.value
  end

  def test_add_path_config
    @meta_config.add_path_config('custom_path', '/custom/path', 'Custom path config')

    assert @config_table.key?('custom_path')
    item = @config_table.lookup('custom_path')
    assert_instance_of ConfigTable::PathItem, item
    assert_equal '/custom/path', item.value
  end

  def test_set_config_default
    item = ConfigTable::Item.new('test', 'template', 'default', 'description')
    @config_table.add(item)

    @meta_config.set_config_default('test', 'new_default')

    assert_equal 'new_default', item.default
  end

  def test_remove_config
    item = ConfigTable::Item.new('test', 'template', 'default', 'description')
    @config_table.add(item)

    @meta_config.remove_config('test')

    refute @config_table.key?('test')
  end

  def test_packages_without_installer_raises_error
    assert_raises(RuntimeError) { @meta_config.packages }
  end

  def test_declare_packages_without_installer_raises_error
    assert_raises(RuntimeError) { @meta_config.declare_packages(['package1']) }
  end

  def test_packages_with_installer
    installer = Object.new
    def installer.packages
      ['package1', 'package2']
    end

    meta_config = ConfigTable::MetaConfigEnvironment.new(@config_table, installer)

    assert_equal ['package1', 'package2'], meta_config.packages
  end

  def test_declare_packages_with_installer
    installer = Object.new
    def installer.packages=(list)
      @packages = list
    end
    def installer.packages
      @packages
    end

    meta_config = ConfigTable::MetaConfigEnvironment.new(@config_table, installer)
    meta_config.declare_packages(['new_package'])

    assert_equal ['new_package'], installer.packages
  end
end