# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/cli'

class TestCLICommandParser < MiniTest::Unit::TestCase

  class SampleCommand < CmdParse::Command
    def initialize
      super('sample', false)
    end
  end

  def setup
    @cli = Webgen::CLI::CommandParser.new
  end

  def test_initialize
    assert_equal(Logger::INFO, @cli.log_level)
    assert_equal(nil, @cli.directory)
  end

  def test_website
    assert_equal(Dir.pwd, @cli.website.directory)
    assert_equal(@cli, @cli.website.ext.cli)
  end

  def test_parse
    @cli.website.ext.cli.add_command(SampleCommand.new)
    out, err = capture_io do
      begin
        @cli.parse(['help'])
        assert_equal(Dir.pwd, @cli.directory + '/')
      rescue SystemExit
      end
    end
    assert_match(/Global options:/, out)
    assert_match(/bundle.*create.*install.*list.*generate.*help.*sample.*.*show.*config.*deps.*extensions.*version/m, out)
  end

end
