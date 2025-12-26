#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'test_helper'

# Test suite for HookScriptAPI module
class HookScriptAPITest < Minitest::Test
  def setup
    @temp_dir = create_temp_dir
    @rbconfig = mock_rbconfig
    @config_table = ConfigTable.new(@rbconfig)
    @config_table.load_standard_entries
    @installer = Installer.new(@config_table, @temp_dir, @temp_dir)
  end

  def teardown
    cleanup_temp_items(@temp_dir)
  end

  def test_get_config
    assert_equal '/usr/local', @installer.get_config('prefix')
  end

  def test_config_alias
    assert_equal '/usr/local', @installer.config('prefix')
  end

  def test_set_config
    @installer.set_config('prefix', '/custom/prefix')
    assert_equal '/custom/prefix', @installer.config('prefix')
  end

  def test_curr_srcdir
    @installer.instance_variable_set(:@currdir, 'subdir')
    expected = File.join(@temp_dir, 'subdir')

    assert_equal expected, @installer.curr_srcdir
  end

  def test_curr_objdir
    @installer.instance_variable_set(:@currdir, 'subdir')
    expected = File.join(@temp_dir, 'subdir')

    assert_equal expected, @installer.curr_objdir
  end

  def test_srcfile
    @installer.instance_variable_set(:@currdir, 'subdir')

    assert_equal File.join(@temp_dir, 'subdir', 'file.rb'), @installer.srcfile('file.rb')
  end

  def test_srcexist_true
    test_file = File.join(@temp_dir, 'test.txt')
    File.write(test_file, 'content')
    @installer.instance_variable_set(:@currdir, '.')

    assert @installer.srcexist?('test.txt')
  end

  def test_srcexist_false
    @installer.instance_variable_set(:@currdir, '.')

    refute @installer.srcexist?('nonexistent.txt')
  end

  def test_srcdirectory_true
    test_dir = File.join(@temp_dir, 'test_dir')
    FileUtils.mkdir_p(test_dir)
    @installer.instance_variable_set(:@currdir, '.')

    assert @installer.srcdirectory?('test_dir')
  end

  def test_srcdirectory_false
    @installer.instance_variable_set(:@currdir, '.')

    refute @installer.srcdirectory?('nonexistent_dir')
  end

  def test_srcfile_true
    test_file = File.join(@temp_dir, 'test.txt')
    File.write(test_file, 'content')
    @installer.instance_variable_set(:@currdir, '.')

    assert @installer.srcfile?('test.txt')
  end

  def test_srcfile_false
    @installer.instance_variable_set(:@currdir, '.')

    refute @installer.srcfile?('nonexistent.txt')
  end

  def test_srcentries
    test_dir = File.join(@temp_dir, 'test_dir')
    FileUtils.mkdir_p(test_dir)
    File.write(File.join(test_dir, 'file1.txt'), 'content1')
    File.write(File.join(test_dir, 'file2.rb'), 'content2')
    FileUtils.mkdir_p(File.join(test_dir, 'subdir'))

    @installer.instance_variable_set(:@currdir, 'test_dir')

    entries = @installer.srcentries

    assert_includes entries, 'file1.txt'
    assert_includes entries, 'file2.rb'
    assert_includes entries, 'subdir'
    refute_includes entries, '.'
    refute_includes entries, '..'
  end

  def test_srcentries_subdirectory
    test_dir = File.join(@temp_dir, 'test_dir')
    sub_dir = File.join(test_dir, 'sub')
    FileUtils.mkdir_p(sub_dir)
    File.write(File.join(sub_dir, 'file.txt'), 'content')

    @installer.instance_variable_set(:@currdir, 'test_dir')

    entries = @installer.srcentries('sub')

    assert_includes entries, 'file.txt'
    refute_includes entries, '.'
    refute_includes entries, '..'
  end

  def test_srcfiles
    test_dir = File.join(@temp_dir, 'test_dir')
    FileUtils.mkdir_p(test_dir)
    File.write(File.join(test_dir, 'file1.txt'), 'content1')
    File.write(File.join(test_dir, 'file2.rb'), 'content2')
    FileUtils.mkdir_p(File.join(test_dir, 'subdir'))

    @installer.instance_variable_set(:@currdir, 'test_dir')

    files = @installer.srcfiles

    assert_equal 2, files.size
    assert_includes files, 'file1.txt'
    assert_includes files, 'file2.rb'
  end

  def test_srcdirectories
    test_dir = File.join(@temp_dir, 'test_dir')
    FileUtils.mkdir_p(test_dir)
    FileUtils.mkdir_p(File.join(test_dir, 'subdir1'))
    FileUtils.mkdir_p(File.join(test_dir, 'subdir2'))
    File.write(File.join(test_dir, 'file.txt'), 'content')

    @installer.instance_variable_set(:@currdir, 'test_dir')

    dirs = @installer.srcdirectories

    assert_equal 2, dirs.size
    assert_includes dirs, 'subdir1'
    assert_includes dirs, 'subdir2'
  end
end