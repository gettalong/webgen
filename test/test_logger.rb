# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/logger'

class TestLogger < Test::Unit::TestCase

  def test_initialize
    l = Webgen::Logger.new(io = StringIO.new)
    assert_equal(:normal, l.verbosity)
    assert_equal(::Logger::WARN, l.level)
    assert_equal(false, l.sync)
  end

  def test_setters
    l = Webgen::Logger.new(io = StringIO.new)
    l.verbosity = :quiet
    l.level = ::Logger::DEBUG
    assert_equal(::Logger::DEBUG, l.level)
    assert_equal(:quiet, l.verbosity)
  end

  def test_log_sync
    l = Webgen::Logger.new(io = StringIO.new, true)
    l.error { 'error' }
    l.stdout { 'hallo' }
    l.warn { 'warn' }
    l.info { 'info' }
    l.debug { 'debug' }
    assert_equal("ERROR -- error\nhallo\n WARN -- warn\n", io.string)
  end

  def test_log_async
    l = Webgen::Logger.new(io = StringIO.new, false)
    l.error { 'error' }
    l.stdout { 'hallo' }
    assert_equal("hallo\n", io.string)
  end

  def test_verbosity_levels
    l = Webgen::Logger.new(io = StringIO.new)
    l.verbose { 'vrb'}
    l.stdout { 'std' }
    assert_equal("std\n", io.string)

    io.string = ''
    l.verbosity = :verbose
    l.verbose { 'vrb' }
    assert_equal("vrb\n", io.string)

    io.string = ''
    l.verbosity = :quiet
    l.stdout { 'vrb' }
    assert_equal("", io.string)
  end

  def test_debug_format
    l = Webgen::Logger.new(io = StringIO.new, true)
    l.level = ::Logger::DEBUG
    l.info('source') { 'hallo' }
    assert_equal(" INFO -- source: hallo\n", io.string)
  end

  def test_log_output
    l = Webgen::Logger.new(io = StringIO.new, true)
    l.error { 'hallo' }
    assert_equal('', l.log_output)

    l = Webgen::Logger.new(io = StringIO.new, false)
    l.error { 'hallo' }
    assert_equal("ERROR -- hallo\n", l.log_output)
  end

  def test_run_marks
    l = Webgen::Logger.new(io = StringIO.new, true)
    l.mark_new_cycle
    l.error { 'hallo' }
    assert_equal("", l.log_output)

    l = Webgen::Logger.new(io = StringIO.new, false)
    l.error { 'hallo' }
    l.mark_new_cycle
    l.error { 'other' }
    l.mark_new_cycle
    assert_equal("ERROR -- hallo\n INFO -- Log messages for run 1 are following\n" +
                 "ERROR -- other\n INFO -- Log messages for run 2 are following\n", l.log_output)

    l = Webgen::Logger.new(io = StringIO.new, false)
    l.mark_new_cycle
    assert_equal("", l.log_output)
  end

end
