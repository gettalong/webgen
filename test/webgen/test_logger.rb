# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'stringio'
require 'webgen/logger'

class TestLogger < Minitest::Test

  def test_logging
    @logio = StringIO.new
    logger = Webgen::Logger.new(@logio)
    logger.formatter = Proc.new do |severity, timestamp, progname, msg|
      "#{severity} #{msg}\n"
    end

    logger.verbose = false
    logger.debug { ["debug", "verbose"]}
    assert_log(/^DEBUG debug$/)
    logger.info {["info", "verbose"]}
    assert_log(/^INFO info$/)
    logger.warn {["warn", "verbose"]}
    assert_log(/^WARN warn$/)
    logger.error {["error", "verbose"]}
    assert_log(/^ERROR error$/)
    logger.vinfo {["verbose", "verbose"]}
    assert_log(/^$/)

    logger.verbose = true
    logger.debug { ["debug", "verbose"]}
    assert_log(/^DEBUG debug\nverbose$/)
    logger.info {["info", "verbose"]}
    assert_log(/^INFO info\nverbose$/)
    logger.warn {["warn", "verbose"]}
    assert_log(/^WARN warn\nverbose$/)
    logger.error {["error", "verbose"]}
    assert_log(/^ERROR error\nverbose$/)
    logger.vinfo {["verbose", "verbose"]}
    assert_log(/^INFO verbose\nverbose$/)
  end

  def assert_log(reg)
    assert_match(reg, @logio.string)
    @logio.string = ''
  end

end
