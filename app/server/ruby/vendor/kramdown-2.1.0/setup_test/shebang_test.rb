#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'test_helper'

# Test suite for Installer::Shebang class
class ShebangTest < Minitest::Test
  def test_load_with_shebang
    temp_file = create_temp_file("#!/usr/bin/ruby\nputs 'hello'")

    shebang = Installer::Shebang.load(temp_file)

    assert_instance_of Installer::Shebang, shebang
    assert_equal '/usr/bin/ruby', shebang.cmd
    assert_empty shebang.args
  ensure
    cleanup_temp_items(temp_file)
  end

  def test_load_with_shebang_and_args
    temp_file = create_temp_file("#!/usr/bin/env ruby -w\nputs 'hello'")

    shebang = Installer::Shebang.load(temp_file)

    assert_instance_of Installer::Shebang, shebang
    assert_equal '/usr/bin/env', shebang.cmd
    assert_equal ['ruby', '-w'], shebang.args
  ensure
    cleanup_temp_items(temp_file)
  end

  def test_load_without_shebang
    temp_file = create_temp_file("puts 'hello'")

    shebang = Installer::Shebang.load(temp_file)

    assert_nil shebang
  ensure
    cleanup_temp_items(temp_file)
  end

  def test_load_empty_file
    temp_file = create_temp_file("")

    shebang = Installer::Shebang.load(temp_file)

    assert_nil shebang
  ensure
    cleanup_temp_items(temp_file)
  end

  def test_parse_simple_shebang
    shebang = Installer::Shebang.parse("#!/usr/bin/ruby")

    assert_equal '/usr/bin/ruby', shebang.cmd
    assert_empty shebang.args
  end

  def test_parse_shebang_with_args
    shebang = Installer::Shebang.parse("#!/usr/bin/env ruby -w")

    assert_equal '/usr/bin/env', shebang.cmd
    assert_equal ['ruby', '-w'], shebang.args
  end

  def test_parse_shebang_with_multiple_args
    shebang = Installer::Shebang.parse("#!/usr/bin/env ruby -w -Ilib")

    assert_equal '/usr/bin/env', shebang.cmd
    assert_equal ['ruby', '-w', '-Ilib'], shebang.args
  end

  def test_parse_shebang_with_spaces
    shebang = Installer::Shebang.parse("#! /usr/bin/ruby ")

    assert_equal '/usr/bin/ruby', shebang.cmd
    assert_empty shebang.args
  end

  def test_initialize_without_args
    shebang = Installer::Shebang.new('/usr/bin/ruby')

    assert_equal '/usr/bin/ruby', shebang.cmd
    assert_empty shebang.args
  end

  def test_initialize_with_args
    shebang = Installer::Shebang.new('/usr/bin/env', ['ruby', '-w'])

    assert_equal '/usr/bin/env', shebang.cmd
    assert_equal ['ruby', '-w'], shebang.args
  end

  def test_to_s_without_args
    shebang = Installer::Shebang.new('/usr/bin/ruby')

    assert_equal '#! /usr/bin/ruby', shebang.to_s
  end

  def test_to_s_with_args
    shebang = Installer::Shebang.new('/usr/bin/env', ['ruby', '-w'])

    assert_equal '#! /usr/bin/env ruby -w', shebang.to_s
  end

  def test_to_s_with_empty_args
    shebang = Installer::Shebang.new('/usr/bin/ruby', [])

    assert_equal '#! /usr/bin/ruby', shebang.to_s
  end
end