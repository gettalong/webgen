# -*- encoding: utf-8 -*-

require 'test/unit'
require 'webgen/cli'

class TestCLICommandParser < Test::Unit::TestCase

  def test_initialize
    cli = Webgen::CLI::CommandParser.new
    assert_equal('render', cli.main_command.default_command)
    assert_equal(:normal, cli.verbosity)
    assert_equal(Logger::WARN, cli.log_level)
    assert_equal(Dir.pwd, cli.directory)
  end

  def test_website_from_env
    ENV['WEBGEN_WEBSITE'] = '/webgen/test/site'
    cli = Webgen::CLI::CommandParser.new
    assert_equal('/webgen/test/site', cli.directory)
  end
end
