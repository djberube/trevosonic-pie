#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'test_helper'

# Test suite for ConfigTable::Item and its subclasses
class ItemClassesTest < Minitest::Test
  def setup
    @rbconfig = mock_rbconfig
    @config_table = ConfigTable.new(@rbconfig)
  end

  # Test base Item class
  def test_item_initialization
    item = ConfigTable::Item.new('test', 'template', 'default', 'description')

    assert_equal 'test', item.name
    assert_equal 'template', item.template
    assert_equal 'default', item.default
    assert_equal 'description', item.description
  end

  def test_item_attr_readers
    item = ConfigTable::Item.new('test', 'template', 'default', 'description')

    assert_equal 'test', item.name
    assert_equal 'description', item.description
  end

  def test_item_default_setter
    item = ConfigTable::Item.new('test', 'template', 'default', 'description')
    item.default = 'new_default'

    assert_equal 'new_default', item.default
  end

  def test_item_help_default
    item = ConfigTable::Item.new('test', 'template', 'default', 'description')

    assert_equal 'default', item.help_default
  end

  def test_item_help_opt
    item = ConfigTable::Item.new('test', 'template', 'default', 'description')

    assert_equal '--test=template', item.help_opt
  end

  def test_item_value?
    item = ConfigTable::Item.new('test', 'template', 'default', 'description')

    assert item.value?
  end

  def test_item_value
    item = ConfigTable::Item.new('test', 'template', 'default', 'description')

    assert_equal 'default', item.value
  end

  def test_item_resolve_without_variables
    item = ConfigTable::Item.new('test', 'template', 'default', 'description')

    assert_equal 'default', item.resolve(@config_table)
  end

  def test_item_resolve_with_variables
    item = ConfigTable::Item.new('test', 'template', '$prefix', 'description')
    @config_table.load_standard_entries

    result = item.resolve(@config_table)
    assert_equal '/usr/local', result
  end

  def test_item_set
    item = ConfigTable::Item.new('test', 'template', 'default', 'description')
    item.set('new_value')

    assert_equal 'new_value', item.value
  end

  def test_item_set_nil_raises_error
    item = ConfigTable::Item.new('test', 'template', 'default', 'description')

    assert_raises(SetupError) { item.set(nil) }
  end

  # Test BoolItem
  def test_bool_item_config_type
    item = ConfigTable::BoolItem.new('test', 'yes/no', 'no', 'description')

    assert_equal 'bool', item.config_type
  end

  def test_bool_item_help_opt
    item = ConfigTable::BoolItem.new('test', 'yes/no', 'no', 'description')

    assert_equal '--test', item.help_opt
  end

  def test_bool_item_check_yes_variations
    item = ConfigTable::BoolItem.new('test', 'yes/no', 'no', 'description')

    assert_equal 'yes', item.send(:check, 'yes')
    assert_equal 'yes', item.send(:check, 'y')
    assert_equal 'yes', item.send(:check, 'true')
    assert_equal 'yes', item.send(:check, 't')
  end

  def test_bool_item_check_no_variations
    item = ConfigTable::BoolItem.new('test', 'yes/no', 'no', 'description')

    assert_equal 'no', item.send(:check, 'no')
    assert_equal 'no', item.send(:check, 'false')
  end

  def test_bool_item_check_case_insensitive
    item = ConfigTable::BoolItem.new('test', 'yes/no', 'no', 'description')

    assert_equal 'yes', item.send(:check, 'YES')
    assert_equal 'no', item.send(:check, 'NO')
  end

  def test_bool_item_check_nil_returns_yes
    item = ConfigTable::BoolItem.new('test', 'yes/no', 'no', 'description')

    assert_equal 'yes', item.send(:check, nil)
  end

  def test_bool_item_check_invalid_raises_error
    item = ConfigTable::BoolItem.new('test', 'yes/no', 'no', 'description')

    assert_raises(SetupError) { item.send(:check, 'invalid') }
  end

  # Test PathItem
  def test_path_item_config_type
    item = ConfigTable::PathItem.new('test', 'path', '/default', 'description')

    assert_equal 'path', item.config_type
  end

  def test_path_item_check_absolute_path
    item = ConfigTable::PathItem.new('test', 'path', '/default', 'description')

    assert_equal '/absolute/path', item.send(:check, '/absolute/path')
  end

  def test_path_item_check_relative_path
    item = ConfigTable::PathItem.new('test', 'path', '/default', 'description')

    result = item.send(:check, 'relative/path')
    assert result.start_with?('/')
    assert result.end_with?('/relative/path')
  end

  def test_path_item_check_variable_path
    item = ConfigTable::PathItem.new('test', 'path', '/default', 'description')

    assert_equal '$variable', item.send(:check, '$variable')
  end

  def test_path_item_check_nil_raises_error
    item = ConfigTable::PathItem.new('test', 'path', '/default', 'description')

    assert_raises(SetupError) { item.send(:check, nil) }
  end

  # Test ProgramItem
  def test_program_item_config_type
    item = ConfigTable::ProgramItem.new('test', 'name', 'default', 'description')

    assert_equal 'program', item.config_type
  end

  # Test SelectItem
  def test_select_item_initialization
    item = ConfigTable::SelectItem.new('test', 'opt1/opt2/opt3', 'opt1', 'description')

    assert_equal ['opt1', 'opt2', 'opt3'], item.instance_variable_get(:@ok)
  end

  def test_select_item_config_type
    item = ConfigTable::SelectItem.new('test', 'opt1/opt2', 'opt1', 'description')

    assert_equal 'select', item.config_type
  end

  def test_select_item_check_valid_option
    item = ConfigTable::SelectItem.new('test', 'opt1/opt2', 'opt1', 'description')

    assert_equal 'opt1', item.send(:check, 'opt1')
    assert_equal 'opt2', item.send(:check, 'opt2')
  end

  def test_select_item_check_strips_whitespace
    item = ConfigTable::SelectItem.new('test', 'opt1/opt2', 'opt1', 'description')

    assert_equal 'opt1', item.send(:check, '  opt1  ')
  end

  def test_select_item_check_invalid_option_raises_error
    item = ConfigTable::SelectItem.new('test', 'opt1/opt2', 'opt1', 'description')

    assert_raises(SetupError) { item.send(:check, 'invalid') }
  end

  # Test ExecItem
  def test_exec_item_initialization
    block = proc { |val, table| }
    item = ConfigTable::ExecItem.new('test', 'opt1/opt2', 'description', &block)

    assert_equal ['opt1', 'opt2'], item.instance_variable_get(:@ok)
    assert_equal block, item.instance_variable_get(:@action)
  end

  def test_exec_item_config_type
    block = proc { |val, table| }
    item = ConfigTable::ExecItem.new('test', 'opt1/opt2', 'description', &block)

    assert_equal 'exec', item.config_type
  end

  def test_exec_item_value?
    block = proc { |val, table| }
    item = ConfigTable::ExecItem.new('test', 'opt1/opt2', 'description', &block)

    refute item.value?
  end

  def test_exec_item_resolve_raises_error
    block = proc { |val, table| }
    item = ConfigTable::ExecItem.new('test', 'opt1/opt2', 'description', &block)

    assert_raises(SetupError) { item.resolve(@config_table) }
  end

  def test_exec_item_set_raises_error
    block = proc { |val, table| }
    item = ConfigTable::ExecItem.new('test', 'opt1/opt2', 'description', &block)

    assert_raises(NoMethodError) { item.set('value') }
  end

  def test_exec_item_evaluate_valid_option
    executed = false
    block = proc { |val, table| executed = true; val }
    item = ConfigTable::ExecItem.new('test', 'opt1/opt2', 'description', &block)

    result = item.evaluate('opt1', @config_table)
    assert executed
    assert_equal 'opt1', result
  end

  def test_exec_item_evaluate_invalid_option_raises_error
    block = proc { |val, table| }
    item = ConfigTable::ExecItem.new('test', 'opt1/opt2', 'description', &block)

    assert_raises(SetupError) { item.evaluate('invalid', @config_table) }
  end

  def test_exec_item_evaluate_downcases_value
    executed = false
    block = proc { |val, table| executed = true; val }
    item = ConfigTable::ExecItem.new('test', 'opt1/opt2', 'description', &block)

    result = item.evaluate('OPT1', @config_table)
    assert executed
    assert_equal 'opt1', result
  end

  # Test PackageSelectionItem
  def test_package_selection_item_initialization
    item = ConfigTable::PackageSelectionItem.new('test', 'name,name...', '', 'ALL', 'description')

    assert_equal 'ALL', item.help_default
  end

  def test_package_selection_item_config_type
    item = ConfigTable::PackageSelectionItem.new('test', 'name,name...', '', 'ALL', 'description')

    assert_equal 'package', item.config_type
  end

  def test_package_selection_item_check_valid_package
    temp_dir = create_temp_dir
    package_dir = File.join(temp_dir, 'packages', 'test_package')
    FileUtils.mkdir_p(package_dir)

    Dir.chdir(temp_dir) do
      item = ConfigTable::PackageSelectionItem.new('test', 'name,name...', '', 'ALL', 'description')
      assert_equal 'test_package', item.send(:check, 'test_package')
    end
  ensure
    cleanup_temp_items(temp_dir)
  end

  def test_package_selection_item_check_invalid_package_raises_error
    item = ConfigTable::PackageSelectionItem.new('test', 'name,name...', '', 'ALL', 'description')

    assert_raises(SetupError) { item.send(:check, 'nonexistent_package') }
  end
end