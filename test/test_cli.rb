# -*- encoding: utf-8 -*-

require 'test/unit'
require 'webgen/cli'
require 'tmpdir'
require 'fileutils'
require 'rbconfig'

class TestCLICommandParser < Test::Unit::TestCase

  def test_initialize
    cli = Webgen::CLI::CommandParser.new
    assert_equal(:normal, cli.verbosity)
    assert_equal(Logger::WARN, cli.log_level)
    assert_equal(nil, cli.directory)
  end

end

if RbConfig::CONFIG['host_os'] !~ /mswin|mingw/

  class TestCLICommands < Test::Unit::TestCase

    def setup
      @dir = File.join(Dir.tmpdir, "webgen-#{Process.pid}")
      @cli = Webgen::CLI::CommandParser.new
    end

    def reroute
      sinread, sinwrite = IO.pipe
      soutread, soutwrite = IO.pipe
      aread, awrite = IO.pipe
      awrite.reopen($stdin)
      aread.reopen($stdout)
      IO.new(0).reopen(sinread)
      IO.new(1).reopen(soutwrite)
      yield(sinwrite, soutread, sinread, soutwrite)
      sinwrite.close_write
      soutwrite.close_write
      soutread
    ensure
      IO.new(0).reopen(awrite)
      IO.new(1).reopen(aread)
    end

    def test_reroute
      soutr = reroute do |sinw, soutr, sinr, soutw|
        soutw.puts "test"
      end
      assert_equal("test\n", soutr.read)
    end

    def teardown
      FileUtils.rm_rf(@dir)
    end

    def test_create_simple
      @cli.parse(['create', @dir])
      assert(File.directory?(@dir))
      assert(File.file?(File.join(@dir, 'config.yaml')))
    end

    def test_create_with_bundles
      @cli.parse(['create', '-b', 'default', '-b', '07', @dir])
      assert(File.directory?(@dir))
      assert(File.file?(File.join(@dir, 'config.yaml')))
      assert(File.file?(File.join(@dir, 'src', 'default.template')))
    end

    def test_create_with_no_bundle
      @cli.parse(['create', '-b', 'none', @dir])
      assert(File.directory?(@dir))
      assert(File.file?(File.join(@dir, 'config.yaml')))
      assert(!File.file?(File.join(@dir, 'src', 'default.template')))
    end

    def test_apply
      assert_raise(RuntimeError) { @cli.parse(['-d', @dir, 'apply', '07']) }
      @cli.parse(['create', '-b', 'none', @dir])
      assert_raise(SystemExit) { reroute { @cli.parse(['-d', @dir, 'apply']) }}
      reroute do |sinwrite, soutread|
        sinwrite.puts "no"
        @cli.parse(['-d', @dir, 'apply', '07'])
      end
      assert(!File.file?(File.join(@dir, 'src', 'default.template')))
      reroute do |sinwrite, soutread|
        sinwrite.puts "yes"
        @cli.parse(['-d', @dir, 'apply', '07'])
      end
      assert(File.file?(File.join(@dir, 'src', 'default.template')))
    end

    def test_apply_forced
      @cli.parse(['create', '-b', 'none', @dir])
      reroute { @cli.parse(['-d', @dir, 'apply', '-f', '07']) }
      assert(File.file?(File.join(@dir, 'src', 'default.template')))
    end

    def test_render
      @cli.parse(['create', @dir])
      reroute { Webgen::CLI::CommandParser.new.parse(['-d', @dir, 'render']) }
      assert(File.file?(File.join(@dir, 'out', 'index.html')))
    end

    def test_all_help
      %w[create apply render].each do |cmd|
        soutr = reroute do
          begin
            @cli.parse(['help', cmd])
          rescue SystemExit
          end
        end
        assert_match(/#{cmd}:.*Usage:/m, soutr.read)
      end
    end

  end

end
