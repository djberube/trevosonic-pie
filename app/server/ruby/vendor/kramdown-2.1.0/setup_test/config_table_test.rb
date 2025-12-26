#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'test_helper'

# Test suite for ConfigTable class
class ConfigTableTest < Minitest::Test
  def setup
    @rbconfig = mock_rbconfig
    @config_table = ConfigTable.new(@rbconfig)
  end

  def test_initialization
    assert_instance_of ConfigTable, @config_table
    assert_equal @rbconfig, @config_table.instance_variable_get(:@rbconfig)
    assert_empty @config_table.instance_variable_get(:@items)
    assert_empty @config_table.instance_variable_get(:@table)
    assert @config_table.verbose?
    refute @config_table.no_harm?
  end

  def test_attr_accessors
    @config_table.install_prefix = '/custom/prefix'
    assert_equal '/custom/prefix', @config_table.install_prefix

    @config_table.config_opt = ['--test']
    assert_equal ['--test'], @config_table.config_opt
  end

  def test_verbose_accessor
    @config_table.verbose = false
    refute @config_table.verbose?

    @config_table.verbose = true
    assert @config_table.verbose?
  end

  def test_no_harm_accessor
    @config_table.no_harm = true
    assert @config_table.no_harm?

    @config_table.no_harm = false
    refute @config_table.no_harm?
  end

  def test_names_empty
    assert_empty @config_table.names
  end

  def test_key_not_found
    refute @config_table.key?('nonexistent')
  end

  def test_lookup_nonexistent_key
    assert_raises(SetupError) { @config_table.lookup('nonexistent') }
  end

  def test_add_item
    item = ConfigTable::Item.new('test', 'template', 'default', 'description')
    @config_table.add(item)

    assert_equal ['test'], @config_table.names
    assert @config_table.key?('test')
    assert_equal item, @config_table.lookup('test')
  end

  def test_remove_item
    item = ConfigTable::Item.new('test', 'template', 'default', 'description')
    @config_table.add(item)

    removed_item = @config_table.remove('test')
    assert_equal item, removed_item
    refute @config_table.key?('test')
    assert_empty @config_table.names
  end

  def test_remove_nonexistent_item
    assert_raises(SetupError) { @config_table.remove('nonexistent') }
  end

  def test_load_script_with_file
    temp_file = create_temp_file(<<~RUBY)
      add_path_config 'test_path', '/test/path', 'Test path config'
      set_config_default 'test_path', '/custom/default'
    RUBY

    @config_table.load_script(temp_file)
    assert @config_table.key?('test_path')
  ensure
    cleanup_temp_items(temp_file)
  end

  def test_load_script_without_file
    @config_table.load_script('/nonexistent/file')
    # Should not raise an error
  end

  def test_savefile
    assert_equal '.config', @config_table.savefile
  end

  def test_load_savefile_with_file
    temp_dir = create_temp_dir
    config_file = File.join(temp_dir, '.config')

    @config_table.load_standard_entries
    File.write(config_file, "prefix=/custom/prefix\n")

    # Change to temp directory to test relative path
    Dir.chdir(temp_dir) do
      @config_table.load_savefile
      assert_equal '/custom/prefix', @config_table['prefix']
    end
  ensure
    cleanup_temp_items(temp_dir)
  end

  def test_load_savefile_without_file
    assert_raises(SetupError) { @config_table.load_savefile }
  end

  def test_save
    temp_dir = create_temp_dir
    config_file = File.join(temp_dir, '.config')

    item = ConfigTable::Item.new('test', 'template', 'default', 'description')
    @config_table.add(item)

    Dir.chdir(temp_dir) do
      @config_table.save
      content = File.read(config_file)
      assert_match(/^test=default$/, content)
    end
  ensure
    cleanup_temp_items(temp_dir)
  end

  def test_load_standard_entries
    @config_table.load_standard_entries
    assert @config_table.key?('prefix')
    assert @config_table.key?('bindir')
    assert @config_table.key?('rubyprog')
  end

  def test_load_multipackage_entries
    @config_table.load_multipackage_entries
    assert @config_table.key?('with')
    assert @config_table.key?('without')
  end

  def test_fixup
    @config_table.load_standard_entries
    @config_table.fixup

    # Test that aliases are set up
    assert_equal @config_table.lookup('rubyprog'), @config_table.lookup('ruby')
    assert_equal @config_table.lookup('makeprog'), @config_table.lookup('make')
  end

  def test_parse_opt_valid
    @config_table.load_standard_entries
    @config_table.fixup

    name, value = @config_table.parse_opt('--prefix=/test')
    assert_equal 'prefix', name
    assert_equal '/test', value
  end

  def test_parse_opt_invalid
    @config_table.load_standard_entries
    @config_table.fixup

    assert_raises(SetupError) { @config_table.parse_opt('--invalid-option') }
  end

  def test_dllext
    assert_equal 'so', @config_table.dllext
  end

  def test_value_config_true
    item = ConfigTable::Item.new('test', 'template', 'default', 'description')
    @config_table.add(item)

    assert @config_table.value_config?('test')
  end

  def test_value_config_false
    item = ConfigTable::ExecItem.new('test', 'template', 'description') {}
    @config_table.add(item)

    refute @config_table.value_config?('test')
  end

  def test_each
    item1 = ConfigTable::Item.new('test1', 'template', 'default', 'description')
    item2 = ConfigTable::Item.new('test2', 'template', 'default', 'description')
    @config_table.add(item1)
    @config_table.add(item2)

    items = []
    @config_table.each { |item| items << item }

    assert_equal [item1, item2], items
  end
end