# -*- encoding: utf-8 -*-

require 'test/unit'
require 'webgen/website'
require 'tmpdir'
require 'fileutils'

class TestWebsite < Test::Unit::TestCase

  def test_initialize
    ws = Webgen::Website.new('dir') do
      assert_equal(ws, Webgen::WebsiteAccess.website)
      throw :called
    end
    assert_nil(ws.blackboard)
    assert_nil(ws.cache)
    assert_nil(ws.config)
    assert_nil(ws.tree)
    assert_equal('dir', ws.directory)
    assert_throws(:called) { ws.init }
    assert_nil(Thread.current[:webgen_website])

    ws = Webgen::Website.new
    assert_equal(Dir.pwd, ws.directory)
    ENV['WEBGEN_WEBSITE'] = 'hallo'
    ws = Webgen::Website.new
    assert_equal('hallo', ws.directory)
    ENV['WEBGEN_WEBSITE'] = ''
    ws = Webgen::Website.new
    assert_equal(Dir.pwd, ws.directory)
  end

  def test_autoload_service
    ws = Webgen::Website.new('unknown', nil)
    ws.init
    ws.instance_eval { @cache = Webgen::Cache.new }
    ws.autoload_service('[]', 'Hash')
    assert_equal([], ws.cache.permanent[:classes])
    ws.blackboard.invoke('[]', 5)
    assert_equal(['Hash'], ws.cache.permanent[:classes])
  end

  def test_init
    ws = Webgen::Website.new('hallo')
    ws.init
    assert_not_nil(ws.config)
    assert_not_nil(ws.blackboard)
    assert_not_nil(ws.cache)
    assert_not_nil(ws.tree)
  end

  def test_render_of_non_webgen_website
    ws = Webgen::Website.new(File.dirname(__FILE__), nil) do |config|
      config['website.cache'] = [:string, '']
    end
    assert_nil(ws.render)
    assert(ws.config['website.cache'][1].length == 0)
  end

  def test_render
    dir = File.join(Dir.tmpdir, 'webgen-' + Process.pid.to_s)
    FileUtils.mkdir_p(dir)
    FileUtils.mkdir_p(File.join(dir, 'src'))
    FileUtils.touch(File.join(dir, 'src', 'test.jpg'))

    ws = Webgen::Website.new(dir, nil)
    assert_equal(:success, ws.render)
    assert_equal(:success, ws.render)
  ensure
    FileUtils.rm_rf(dir)
  end

  def test_execute_in_env
    ws = Webgen::Website.new('hallo')
    assert_nil(Webgen::WebsiteAccess.website)
    ws.execute_in_env { assert_not_nil(Webgen::WebsiteAccess.website) }
    assert_nil(Webgen::WebsiteAccess.website)
    ws.execute_in_env do
      assert_equal(ws, Webgen::WebsiteAccess.website)
      ws2 = Webgen::Website.new("hallo2")
      ws2.execute_in_env { assert_equal(ws2, Webgen::WebsiteAccess.website) }
      assert_equal(ws, Webgen::WebsiteAccess.website)
    end
    assert_equal(nil, Webgen::WebsiteAccess.website)
  end

  def test_read_config_file
    dir = File.join(Dir.tmpdir, 'webgen-' + Process.pid.to_s)
    FileUtils.mkdir_p(dir)

    ws = Webgen::Website.new(dir)
    ws.init
    assert_equal('', ws.logger.log_output)
    FileUtils.touch(File.join(dir, 'config.yml'))
    ws.init
    assert_match(/spelling error/, ws.logger.log_output)

    File.open(File.join(dir, 'config.yaml'), 'w+') {|f| f.write('- unknown')}
    assert_raise(Webgen::Website::ConfigFileInvalid) { ws.init }

    File.open(File.join(dir, 'config.yaml'), 'w+') {|f| f.write('webgen.unknown: doit')}
    assert_raise(Webgen::Website::ConfigFileInvalid) { ws.init }

    File.open(File.join(dir, 'config.yaml'), 'w+') {|f| f.write("website.lang: de\ndefault_meta_info: {:all: {hallo: du}}")}
    ws.init
    assert_equal('de', ws.config['website.lang'])
    assert_equal('du', ws.config['sourcehandler.default_meta_info'][:all]['hallo'])
  ensure
    FileUtils.rm_rf(dir)
  end

  def test_clean
    dir = File.join(Dir.tmpdir, 'webgen-' + Process.pid.to_s)
    FileUtils.mkdir_p(dir)
    FileUtils.mkdir_p(File.join(dir, 'src'))
    FileUtils.touch(File.join(dir, 'src', 'test.jpg'))

    ws = Webgen::Website.new(dir, nil)
    assert_equal(:success, ws.render)
    assert(File.exists?(File.join(dir, 'out', 'test.jpg')))
    ws.clean
    assert(!File.exists?(File.join(dir, 'out', 'test.jpg')))
    assert(File.directory?(File.join(dir, 'out')))
    ws.clean(true)
    assert(!File.directory?(File.join(dir, 'out')))
  ensure
    FileUtils.rm_rf(dir)
  end

end
