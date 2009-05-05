# -*- encoding: utf-8 -*-

require 'test/unit'
require 'webgen/cli'

class TestCLICommandParser < Test::Unit::TestCase

  def test_initialize
    cli = Webgen::CLI::CommandParser.new
    assert_equal(:normal, cli.verbosity)
    assert_equal(Logger::WARN, cli.log_level)
    assert_equal(nil, cli.directory)
  end

end
