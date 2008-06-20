require 'test/unit'
require 'webgen/website'


class TestWebsite < Test::Unit::TestCase

  def test_initialize
    ws = Webgen::Website.new do
      assert_equal(ws, Webgen::WebsiteAccess.website)
      throw :called
    end
    assert_not_nil(ws.blackboard)
    assert_nil(ws.cache)
    assert_nil(ws.config)
    assert_throws(:called) { ws.init }
    assert_nil(Thread.current[:webgen_website])
  end

  def test_autoload_service
    ws = Webgen::Website.new
    ws.instance_eval { @cache = Webgen::Cache.new }
    ws.autoload_service('[]', 'Hash')
    assert_equal([], ws.cache.permanent[:classes])
    ws.blackboard.invoke('[]', 5)
    assert_equal(['Hash'], ws.cache.permanent[:classes])
  end

  def test_init
    ws = Webgen::Website.new {|config| config['website.dir'] = 'hallo' }
    ws.init
    assert_not_nil(ws.config)
    assert_equal('hallo', ws.config['website.dir'])
  end

  def test_render
    ws = Webgen::Website.new do |config|
      config['website.dir'] = File.dirname(__FILE__)
      config['website.cache'] = [:string, '']
    end
    ws.logger = nil
    ws.render
    assert(ws.config['website.cache'][1].length > 0)
  end

end
