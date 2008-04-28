require 'test/unit'
require 'webgen/website'


class TestWebsite < Test::Unit::TestCase

  def test_initialize
    ws = Webgen::Website.new do
      assert_equal(ws, Webgen::WebsiteAccess.website)
      throw :called
    end
    assert_not_nil(ws.blackboard)
    assert_not_nil(ws.cache)
    assert_throws(:called) { ws.init }
    assert_nil(Thread.current[:webgen_website])
  end

end
