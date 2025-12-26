#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'test_helper'

# Test suite for Installer class
class InstallerTest < Minitest::Test
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

  def test_initialization
    assert_instance_of Installer, @installer
    assert_equal @config_table, @installer.instance_variable_get(:@config)
    assert_equal @temp_dir, @installer.instance_variable_get(:@srcdir)
    assert_equal @temp_dir, @installer.instance_variable_get(:@objdir)
    assert_equal '.', @installer.instance_variable_get(:@currdir)
  end

  def test_inspect
    expected = "#<Installer #{File.basename(@temp_dir)}>"

    assert_equal expected, @installer.inspect
  end

  def test_noop
    # noop should do nothing and return nil
    assert_nil @installer.noop('rel')
  end

  def test_srcdir_root
    assert_equal @temp_dir, @installer.srcdir_root
  end

  def test_objdir_root
    assert_equal @temp_dir, @installer.objdir_root
  end

  def test_relpath
    assert_equal '.', @installer.relpath
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

  def test_verbose_off
    @config_table.verbose = true

    @installer.verbose_off do
      refute @installer.verbose?
    end

    assert @installer.verbose?
  end

  def test_extdir_with_extconf
    ext_dir = File.join(@temp_dir, 'ext')
    FileUtils.mkdir_p(ext_dir)
    File.write(File.join(ext_dir, 'extconf.rb'), '# extconf')

    assert @installer.extdir?(File.join(@temp_dir, 'ext'))
  end

  def test_extdir_with_manifest
    ext_dir = File.join(@temp_dir, 'ext')
    FileUtils.mkdir_p(ext_dir)
    File.write(File.join(ext_dir, 'MANIFEST'), 'files')

    assert @installer.extdir?(File.join(@temp_dir, 'ext'))
  end

  def test_extdir_false
    regular_dir = File.join(@temp_dir, 'regular')
    FileUtils.mkdir_p(regular_dir)

    refute @installer.extdir?(regular_dir)
  end

  def test_files_of
    test_dir = File.join(@temp_dir, 'test')
    FileUtils.mkdir_p(test_dir)
    File.write(File.join(test_dir, 'file1.txt'), 'content1')
    File.write(File.join(test_dir, 'file2.rb'), 'content2')
    FileUtils.mkdir_p(File.join(test_dir, 'subdir'))

    files = @installer.files_of(test_dir)

    assert_equal 2, files.size
    assert_includes files, 'file1.txt'
    assert_includes files, 'file2.rb'
  end

  def test_directories_of
    test_dir = File.join(@temp_dir, 'test')
    FileUtils.mkdir_p(test_dir)
    FileUtils.mkdir_p(File.join(test_dir, 'subdir1'))
    FileUtils.mkdir_p(File.join(test_dir, 'subdir2'))
    File.write(File.join(test_dir, 'file.txt'), 'content')

    dirs = @installer.directories_of(test_dir)

    assert_equal 2, dirs.size
    assert_includes dirs, 'subdir1'
    assert_includes dirs, 'subdir2'
  end

  def test_existfiles
    test_dir = File.join(@temp_dir, 'test')
    FileUtils.mkdir_p(test_dir)
    File.write(File.join(test_dir, 'file1.txt'), 'content1')
    File.write(File.join(test_dir, 'file2.rb'), 'content2')
    FileUtils.mkdir_p(File.join(test_dir, 'subdir'))

    Dir.chdir(test_dir) do
      files = @installer.existfiles
      assert_equal 2, files.size
      assert_includes files, 'file1.txt'
      assert_includes files, 'file2.rb'
    end
  end

  def test_hookfiles
    expected = [
      'pre-config', 'post-config',
      'pre-setup', 'post-setup',
      'pre-install', 'post-install',
      'pre-clean', 'post-clean'
    ]

    hookfiles = @installer.hookfiles
    expected.each do |hook|
      assert_includes hookfiles, hook
      assert_includes hookfiles, "#{hook}.rb"
    end
  end

  def test_targetfiles
    Dir.chdir(@temp_dir) do
      File.write('file1.txt', 'content1')
      File.write('file2.rb', 'content2')

      files = @installer.targetfiles
      assert_includes files, 'file1.txt'
      assert_includes files, 'file2.rb'
    end
  end

  def test_mapdir_with_existing_files
    files = ['file1.txt', 'file2.rb']
    Dir.chdir(@temp_dir) do
      File.write('file1.txt', 'content1')
      File.write('file2.rb', 'content2')
    end

    Dir.chdir(@temp_dir) do
      mapped = @installer.mapdir(files)
      assert_equal files, mapped
    end
  end



  def test_glob_select
    Dir.chdir(@temp_dir) do
      File.write('file1.txt', 'content1')
      File.write('file2.rb', 'content2')
      File.write('file3.txt', 'content3')
    end

    ents = ['file1.txt', 'file2.rb', 'file3.txt']
    selected = @installer.glob_select('*.txt', ents)

    assert_equal 2, selected.size
    assert_includes selected, 'file1.txt'
    assert_includes selected, 'file3.txt'
  end

  def test_glob_reject
    Dir.chdir(@temp_dir) do
      File.write('file1.txt', 'content1')
      File.write('file2.rb', 'content2')
      File.write('file3.txt', 'content3')
    end

    ents = ['file1.txt', 'file2.rb', 'file3.txt']
    rejected = @installer.glob_reject(['*.txt'], ents)

    assert_equal 1, rejected.size
    assert_includes rejected, 'file2.rb'
  end

  def test_globs2re_single_pattern
    re = @installer.globs2re(['*.txt'])

    assert_match re, 'file.txt'
    refute_match re, 'file.rb'
  end

  def test_globs2re_multiple_patterns
    re = @installer.globs2re(['*.txt', '*.rb'])

    assert_match re, 'file.txt'
    assert_match re, 'file.rb'
    refute_match re, 'file.py'
  end

  def test_globs2re_with_special_chars
    re = @installer.globs2re(['test.*'])

    assert_match re, 'test.txt'
    assert_match re, 'test.rb'
    refute_match re, 'other.txt'
  end

  def test_libfiles
    Dir.chdir(@temp_dir) do
      File.write('file1.txt', 'content1')
      File.write('file2.rb', 'content2')
      File.write('file3.y', 'content3')

      libfiles = @installer.libfiles

      assert_includes libfiles, 'file1.txt'
      assert_includes libfiles, 'file2.rb'
      refute_includes libfiles, 'file3.y'
    end
  end

  def test_rubyextentions_with_extensions
    Dir.chdir(@temp_dir) do
      File.write('ext.so', 'binary')
      File.write('other.txt', 'text')

      exts = @installer.rubyextentions('.')

      assert_includes exts, 'ext.so'
    end
  end

  def test_rubyextentions_without_extensions
    Dir.chdir(@temp_dir) do
      File.write('file1.txt', 'content1')
      File.write('file2.rb', 'content2')
    end

    assert_raises(SetupError) { @installer.rubyextentions('.') }
  end

  def test_run_hook_with_existing_hook
    hook_file = File.join(@temp_dir, 'pre-config')
    File.write(hook_file, 'puts "hook executed"')

    # Capture stdout to verify hook execution
    output = capture_io { @installer.run_hook('pre-config') }.first

    assert_match(/hook executed/, output)
  end

  def test_run_hook_with_ruby_hook
    hook_file = File.join(@temp_dir, 'pre-config.rb')
    File.write(hook_file, 'puts "ruby hook executed"')

    output = capture_io { @installer.run_hook('pre-config') }.first

    assert_match(/ruby hook executed/, output)
  end

  def test_run_hook_without_hook
    # Should not raise an error
    @installer.run_hook('nonexistent-hook')
  end

  def test_run_hook_with_error
    hook_file = File.join(@temp_dir, 'pre-config.rb')
    File.write(hook_file, 'raise "hook error"')

    assert_raises(SetupError) { @installer.run_hook('pre-config') }
  end

  def test_dive_into_with_existing_directory
    sub_dir = File.join(@temp_dir, 'subdir')
    FileUtils.mkdir_p(sub_dir)

    original_dir = Dir.pwd
    @installer.dive_into('subdir') do
      assert_equal File.join(original_dir, 'subdir'), Dir.pwd
      assert_equal 'subdir', @installer.instance_variable_get(:@currdir)
    end

    assert_equal original_dir, Dir.pwd
    assert_equal '.', @installer.instance_variable_get(:@currdir)
  end

  def test_dive_into_with_nonexistent_directory
    # Should not yield if directory doesn't exist
    yielded = false
    @installer.dive_into('nonexistent') { yielded = true }

    refute yielded
  end
end