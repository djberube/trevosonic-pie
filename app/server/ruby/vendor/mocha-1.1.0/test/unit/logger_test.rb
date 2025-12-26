require File.expand_path("../../test_helper", __FILE__)
require "mocha/logger"

class LoggerTest < Mocha::TestCase
  include Mocha

  def setup
    @output = StringIO.new
    @logger = Mocha::Logger.new(@output)
  end

  def test_initialize_with_valid_io
    logger = Mocha::Logger.new(@output)
    assert_equal @output, logger.io
    assert_equal :warn, logger.level
    assert_equal "%Y-%m-%d %H:%M:%S", logger.timestamp_format
  end

  def test_initialize_with_custom_level
    logger = Mocha::Logger.new(@output, level: :debug)
    assert_equal :debug, logger.level
  end

  def test_initialize_with_custom_timestamp_format
    logger = Mocha::Logger.new(@output, timestamp_format: "%H:%M")
    assert_equal "%H:%M", logger.timestamp_format
  end

  def test_initialize_with_nil_timestamp_format
    logger = Mocha::Logger.new(@output, timestamp_format: nil)
    assert_nil logger.timestamp_format
  end

  def test_initialize_raises_error_for_nil_io
    assert_raises(ArgumentError, "IO cannot be nil") do
      Mocha::Logger.new(nil)
    end
  end

  def test_initialize_raises_error_for_invalid_io
    assert_raises(ArgumentError, "IO must respond to #puts") do
      Mocha::Logger.new(Object.new)
    end
  end

  def test_initialize_raises_error_for_invalid_level
    assert_raises(ArgumentError, /Invalid log level/) do
      Mocha::Logger.new(@output, level: :invalid)
    end
  end

  def test_warn_logs_message_at_warn_level
    @logger.warn("Test warning")
    output = @output.string
    assert_match /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} \[WARN\] Test warning/, output
  end

  def test_warn_logs_message_without_timestamp_when_disabled
    logger = Mocha::Logger.new(@output, timestamp_format: nil)
    logger.warn("Test warning")
    output = @output.string
    assert_match /\[WARN\] Test warning/, output
    refute_match /\d{4}-\d{2}-\d{2}/, output
  end

  def test_fatal_logs_at_fatal_level
    @logger.level = :fatal
    @logger.fatal("Fatal error")
    output = @output.string
    assert_match /\[FATAL\] Fatal error/, output
  end

  def test_error_logs_at_error_level
    @logger.level = :error
    @logger.error("Error message")
    output = @output.string
    assert_match /\[ERROR\] Error message/, output
  end

  def test_info_logs_at_info_level
    @logger.level = :info
    @logger.info("Info message")
    output = @output.string
    assert_match /\[INFO\] Info message/, output
  end

  def test_debug_logs_at_debug_level
    @logger.level = :debug
    @logger.debug("Debug message")
    output = @output.string
    assert_match /\[DEBUG\] Debug message/, output
  end

  def test_messages_not_logged_below_current_level
    @logger.level = :warn
    @logger.info("Should not log")
    @logger.debug("Should not log")
    assert_empty @output.string
  end

  def test_messages_logged_at_or_above_current_level
    @logger.level = :info
    @logger.warn("Should log")
    @logger.error("Should log")
    @logger.info("Should log")
    output = @output.string
    assert_match /\[WARN\] Should log/, output
    assert_match /\[ERROR\] Should log/, output
    assert_match /\[INFO\] Should log/, output
  end

  def test_level_setter_changes_level
    @logger.level = :debug
    assert_equal :debug, @logger.level
    @logger.debug("Debug message")
    assert_match /\[DEBUG\] Debug message/, @output.string
  end

  def test_level_setter_validates_input
    assert_raises(ArgumentError, /Invalid log level/) do
      @logger.level = :invalid_level
    end
  end

  def test_message_conversion_to_string
    @logger.warn(123)
    output = @output.string
    assert_match /\[WARN\] 123/, output
  end

  def test_message_conversion_handles_nil
    @logger.warn(nil)
    output = @output.string
    assert_match /\[WARN\]/, output
  end

  def test_handles_io_errors_gracefully
    # Create a mock IO that raises an error
    error_io = Class.new do
      def puts(*args)
        raise IOError, "Test IO error"
      end
      def closed?
        false
      end
    end.new

    logger = Mocha::Logger.new(error_io)
    # Should not raise an error
    assert_nothing_raised do
      logger.warn("Test message")
    end
  end

  def test_handles_closed_io_gracefully
    closed_io = StringIO.new
    closed_io.close

    logger = Mocha::Logger.new(closed_io)
    # Should not raise an error when IO is closed
    logger.warn("Test message")
  end

  def test_log_levels_constant_is_frozen
    assert Mocha::Logger::LOG_LEVELS.frozen?
  end

  def test_default_constants
    assert_equal :warn, Mocha::Logger::DEFAULT_LEVEL
    assert_equal "%Y-%m-%d %H:%M:%S", Mocha::Logger::DEFAULT_TIMESTAMP_FORMAT
  end

  def test_all_log_levels_work
    @logger.level = :debug
    Mocha::Logger::LOG_LEVELS.keys.each do |level|
      @logger.send(level, "#{level} message")
      output = @output.string
      assert_match /\[#{level.upcase}\] #{level} message/, output
    end
  end

  def test_custom_timestamp_format
    logger = Mocha::Logger.new(@output, timestamp_format: "%Y")
    logger.warn("Test")
    output = @output.string
    assert_match /\d{4} \[WARN\] Test/, output
  end

  def test_backward_compatibility_with_old_warn_method
    # Ensure the old API still works
    @logger.warn("Old style warning")
    output = @output.string
    assert_match /\[WARN\] Old style warning/, output
  end

  def test_multiple_messages_are_logged_separately
    @logger.warn("First message")
    @logger.error("Second message")
    output = @output.string
    lines = output.strip.split("\n")
    assert_equal 2, lines.size
    assert_match /\[WARN\] First message/, lines[0]
    assert_match /\[ERROR\] Second message/, lines[1]
  end

  def test_io_attr_reader
    assert_equal @output, @logger.io
  end

  def test_level_attr_reader
    assert_equal :warn, @logger.level
  end

  def test_timestamp_format_attr_reader
    assert_equal "%Y-%m-%d %H:%M:%S", @logger.timestamp_format
  end
end