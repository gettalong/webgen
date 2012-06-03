# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require 'webgen/extension_loader'

class TestExtensionLoader < MiniTest::Unit::TestCase

  def setup
    @website = MiniTest::Mock.new
    @website.expect(:config, {'sources.passive' => [['/', :file, 'other']]})
    @dir = File.join(Dir.tmpdir, 'test-webgen')
    @website.expect(:directory, @dir)

    @extdir = File.join(@dir, 'ext')
    FileUtils.mkdir_p(File.join(@extdir, 'my_ext'))
    FileUtils.mkdir_p(File.join(@extdir, 'webgen'))
    @webgen_file = File.join(@extdir, 'webgen', 'init.rb')
    FileUtils.touch(@webgen_file)
    @ext_file = File.join(@extdir, 'my_ext', 'init.rb')
    FileUtils.touch(@ext_file)

    @loader = Webgen::ExtensionLoader.new(@website, @extdir)
  end

  def teardown
    FileUtils.rm_rf(@dir)
  end

  def test_load
    @loader.load('webgen')
    @loader.load('my_ext')
    @loader.load('my_ext')
    assert_equal([File.expand_path(@webgen_file), File.expand_path(@ext_file)], @loader.instance_variable_get(:@loaded))
  end

  def test_dsl
    File.open(File.join(@extdir, 'init.rb'), 'w+') do |f|
      f.puts("load('my_ext'); require_relative('webgen/init.rb')")
    end
    File.open(@ext_file, 'w+') do |f|
      f.puts("mount_passive('data', '/test')")
    end
    @loader.load('init.rb')
    assert($LOADED_FEATURES.include?(@webgen_file))
    assert_equal([['/test', :file_system, File.expand_path(File.dirname(@ext_file) + '/data')],
                  ['/', :file, 'other']], @website.config['sources.passive'])
  end

end
