require 'test/unit'
require 'helper'
require 'webgen/loggable'
require 'webgen/logger'
require 'stringio'

class TestLoggable < Test::Unit::TestCase

  include Test::WebsiteHelper

  def setup
    super
    @website.logger = Webgen::Logger.new(@io = StringIO.new, true)
    @obj = Object.new
    @obj.extend(Webgen::Loggable)
  end

  def test_log
    @obj.log(:error) { 'hallo' }
    assert_equal("ERROR -- hallo\n", @io.string)
  end

  def test_puts
    @obj.puts 'test'
    assert_equal("test\n", @io.string)
    @obj.puts 'test', :verbose
    assert_equal("test\n", @io.string)
  end

end
