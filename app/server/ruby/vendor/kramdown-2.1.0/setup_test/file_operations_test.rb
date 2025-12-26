#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'test_helper'

# Test suite for FileOperations module
class FileOperationsTest < Minitest::Test
  include FileOperations

  def setup
    @temp_dir = create_temp_dir
    @verbose = true
    @no_harm = false
  end

  def teardown
    cleanup_temp_items(@temp_dir)
  end

  def verbose?
    @verbose
  end

  def no_harm?
    @no_harm
  end

  def verbose_off
    begin
      save, @verbose = @verbose, false
      yield
    ensure
      @verbose = save
    end
  end

  def objdir_root
    @temp_dir
  end

  def test_mkdir_p_with_prefix
    subdir = 'test/subdir'
    prefix = @temp_dir

    mkdir_p(subdir, prefix)

    full_path = File.join(prefix, subdir)
    assert File.directory?(full_path)
  end

  def test_mkdir_p_without_prefix
    subdir = File.join(@temp_dir, 'test/subdir')

    Dir.chdir(@temp_dir) do
      mkdir_p('test/subdir')
    end

    assert File.directory?(subdir)
  end

  def test_mkdir_p_no_harm_mode
    @no_harm = true
    subdir = File.join(@temp_dir, 'test/subdir')

    mkdir_p(subdir)

    refute File.directory?(subdir)
  end

  def test_rm_f_existing_file
    test_file = File.join(@temp_dir, 'test.txt')
    File.write(test_file, 'content')

    rm_f(test_file)

    refute File.exist?(test_file)
  end

  def test_rm_f_nonexistent_file
    nonexistent_file = File.join(@temp_dir, 'nonexistent.txt')

    rm_f(nonexistent_file)
    # Should not raise an error
  end

  def test_rm_f_no_harm_mode
    test_file = File.join(@temp_dir, 'test.txt')
    File.write(test_file, 'content')

    @no_harm = true
    rm_f(test_file)

    assert File.exist?(test_file)
  end

  def test_rm_rf_directory
    test_dir = File.join(@temp_dir, 'test_dir')
    FileUtils.mkdir_p(test_dir)
    File.write(File.join(test_dir, 'file.txt'), 'content')

    rm_rf(test_dir)

    refute File.exist?(test_dir)
  end

  def test_rm_rf_file
    test_file = File.join(@temp_dir, 'test.txt')
    File.write(test_file, 'content')

    rm_rf(test_file)

    refute File.exist?(test_file)
  end

  def test_rm_rf_no_harm_mode
    test_dir = File.join(@temp_dir, 'test_dir')
    FileUtils.mkdir_p(test_dir)

    @no_harm = true
    rm_rf(test_dir)

    assert File.exist?(test_dir)
  end

  def test_remove_tree_directory
    test_dir = File.join(@temp_dir, 'test_dir')
    FileUtils.mkdir_p(test_dir)
    File.write(File.join(test_dir, 'file.txt'), 'content')

    remove_tree(test_dir)

    refute File.exist?(test_dir)
  end

  def test_remove_tree_symlink
    target_file = File.join(@temp_dir, 'target.txt')
    File.write(target_file, 'content')
    symlink = File.join(@temp_dir, 'symlink')
    File.symlink(target_file, symlink)

    remove_tree(symlink)

    refute File.exist?(symlink)
    assert File.exist?(target_file) # Target should remain
  end

  def test_remove_tree_file
    test_file = File.join(@temp_dir, 'test.txt')
    File.write(test_file, 'content')

    remove_tree(test_file)

    refute File.exist?(test_file)
  end

  def test_remove_tree0_with_nested_structure
    test_dir = File.join(@temp_dir, 'test_dir')
    FileUtils.mkdir_p(File.join(test_dir, 'subdir'))
    File.write(File.join(test_dir, 'file1.txt'), 'content1')
    File.write(File.join(test_dir, 'subdir', 'file2.txt'), 'content2')

    remove_tree0(test_dir)

    refute File.exist?(test_dir)
  end

  def test_move_file
    src_file = File.join(@temp_dir, 'source.txt')
    dest_file = File.join(@temp_dir, 'dest.txt')
    content = 'test content'

    File.write(src_file, content)
    src_mode = File.stat(src_file).mode
    move_file(src_file, dest_file)

    refute File.exist?(src_file)
    assert File.exist?(dest_file)
    assert_equal content, File.read(dest_file)
    assert_equal src_mode, File.stat(dest_file).mode
  end

  def test_move_file_dest_exists
    src_file = File.join(@temp_dir, 'source.txt')
    dest_file = File.join(@temp_dir, 'dest.txt')
    src_content = 'source content'
    dest_content = 'dest content'

    File.write(src_file, src_content)
    File.write(dest_file, dest_content)

    move_file(src_file, dest_file)

    refute File.exist?(src_file)
    assert File.exist?(dest_file)
    assert_equal src_content, File.read(dest_file)
  end

  def test_force_remove_file
    test_file = File.join(@temp_dir, 'test.txt')
    File.write(test_file, content = 'content')

    # Make file read-only to test force removal
    File.chmod(0444, test_file)

    force_remove_file(test_file)

    refute File.exist?(test_file)
  end

  def test_remove_file
    test_file = File.join(@temp_dir, 'test.txt')
    File.write(test_file, 'content')

    remove_file(test_file)

    refute File.exist?(test_file)
  end

  def test_install_file_to_directory
    src_file = File.join(@temp_dir, 'source.txt')
    dest_dir = File.join(@temp_dir, 'dest')
    content = 'test content'

    File.write(src_file, content)
    FileUtils.mkdir_p(dest_dir)

    install(src_file, dest_dir, 0644)

    installed_file = File.join(dest_dir, 'source.txt')
    assert File.exist?(installed_file)
    assert_equal content, File.read(installed_file)
    assert_equal 0644, File.stat(installed_file).mode & 0777
  end

  def test_install_file_to_file
    src_file = File.join(@temp_dir, 'source.txt')
    dest_file = File.join(@temp_dir, 'dest.txt')
    content = 'test content'

    File.write(src_file, content)

    install(src_file, dest_file, 0644)

    assert File.exist?(dest_file)
    assert_equal content, File.read(dest_file)
    assert_equal 0644, File.stat(dest_file).mode & 0777
  end

  def test_install_no_harm_mode
    src_file = File.join(@temp_dir, 'source.txt')
    dest_file = File.join(@temp_dir, 'dest.txt')

    File.write(src_file, 'content')

    @no_harm = true
    install(src_file, dest_file, 0644)

    refute File.exist?(dest_file)
  end

  def test_install_with_prefix
    src_file = File.join(@temp_dir, 'source.txt')
    dest_file = 'dest.txt'
    prefix = @temp_dir
    content = 'test content'

    File.write(src_file, content)

    install(src_file, dest_file, 0644, prefix)

    full_dest = File.join(prefix, dest_file)
    assert File.exist?(full_dest)
    assert_equal content, File.read(full_dest)
  end

  def test_diff_same_content
    test_file = File.join(@temp_dir, 'test.txt')
    content = 'test content'

    File.write(test_file, content)

    refute diff?(content, test_file)
  end

  def test_diff_different_content
    test_file = File.join(@temp_dir, 'test.txt')

    File.write(test_file, 'old content')

    assert diff?('new content', test_file)
  end

  def test_diff_nonexistent_file
    nonexistent_file = File.join(@temp_dir, 'nonexistent.txt')

    assert diff?('content', nonexistent_file)
  end

  def test_command_success
    # Use a simple command that should succeed
    command('true')
  end

  def test_command_failure
    assert_raises(RuntimeError) { command('false') }
  end

  def test_ruby_command
    # Test that ruby method calls command with rubyprog
    # This is tricky to test without mocking, so we'll just ensure it doesn't raise
    rbconfig = mock_rbconfig
    config_table = ConfigTable.new(rbconfig)
    config_table.load_standard_entries

    # Mock the config method
    def self.config(key)
      case key
      when 'rubyprog' then 'ruby'
      else raise "Unexpected config key: #{key}"
      end
    end

    # This should not raise an error
    ruby('--version')
  end

  def test_make_command
    # Similar to ruby test
    def self.config(key)
      case key
      when 'makeprog' then 'make'
      else raise "Unexpected config key: #{key}"
      end
    end

    # This might fail if make is not available, but shouldn't raise our error
    begin
      make('--version')
    rescue RuntimeError => e
      assert_match(/system\(.+\) failed/, e.message)
    end
  end

  def test_extdir_true
    ext_dir = File.join(@temp_dir, 'ext')
    FileUtils.mkdir_p(ext_dir)
    File.write(File.join(ext_dir, 'extconf.rb'), '# extconf')

    assert extdir?(ext_dir)
  end

  def test_extdir_false
    regular_dir = File.join(@temp_dir, 'regular')
    FileUtils.mkdir_p(regular_dir)

    refute extdir?(regular_dir)
  end

  def test_extdir_with_manifest
    ext_dir = File.join(@temp_dir, 'ext')
    FileUtils.mkdir_p(ext_dir)
    File.write(File.join(ext_dir, 'MANIFEST'), 'files')

    assert extdir?(ext_dir)
  end

  def test_files_of_directory
    test_dir = File.join(@temp_dir, 'test')
    FileUtils.mkdir_p(test_dir)
    File.write(File.join(test_dir, 'file1.txt'), 'content1')
    File.write(File.join(test_dir, 'file2.rb'), 'content2')
    FileUtils.mkdir_p(File.join(test_dir, 'subdir'))

    files = files_of(test_dir)

    assert_equal 2, files.size
    assert_includes files, 'file1.txt'
    assert_includes files, 'file2.rb'
  end

  def test_directories_of_directory
    test_dir = File.join(@temp_dir, 'test')
    FileUtils.mkdir_p(test_dir)
    FileUtils.mkdir_p(File.join(test_dir, 'subdir1'))
    FileUtils.mkdir_p(File.join(test_dir, 'subdir2'))
    File.write(File.join(test_dir, 'file.txt'), 'content')

    dirs = directories_of(test_dir)

    assert_equal 2, dirs.size
    assert_includes dirs, 'subdir1'
    assert_includes dirs, 'subdir2'
  end

  def test_directories_of_excludes_special_dirs
    test_dir = File.join(@temp_dir, 'test')
    FileUtils.mkdir_p(test_dir)
    FileUtils.mkdir_p(File.join(test_dir, '.git'))
    FileUtils.mkdir_p(File.join(test_dir, 'CVS'))
    FileUtils.mkdir_p(File.join(test_dir, 'regular_dir'))

    dirs = directories_of(test_dir)

    assert_equal 1, dirs.size
    assert_includes dirs, 'regular_dir'
  end
end