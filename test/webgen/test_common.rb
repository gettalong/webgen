# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/common'

class TestCommon < MiniTest::Unit::TestCase

  def test_class_const_for_name
    assert_equal Webgen::Common, Webgen::Common.const_for_name('Webgen::Common')
  end

  def test_class_snake_case
    assert_equal('webgen/html_error_now', Webgen::Common.snake_case('Webgen::HTMLErrorNow'))
  end

  def test_class_url
    assert_equal("webgen://webgen.localhost/hallo", Webgen::Common.url("hallo").to_s)
    assert_equal("webgen://webgen.localhost/hallo%20du", Webgen::Common.url("hallo du").to_s)
    assert_equal("webgen://webgen.localhost/hall%C3%B6chen", Webgen::Common.url("hallöchen").to_s)
    assert_equal("webgen://webgen.localhost/hallo#du", Webgen::Common.url("hallo#du").to_s)

    assert_equal("webgen://webgen.localhost/test", Webgen::Common.url("/test").to_s)
    assert_equal("http://example.com/test", Webgen::Common.url("http://example.com/test").to_s)

    assert_equal("test", Webgen::Common.url("test", false).to_s)
    assert_equal("http://example.com/test", Webgen::Common.url("http://example.com/test", false).to_s)
  end

  def test_class_append_path
    assert_raises(ArgumentError) { Webgen::Common.append_path('test', 'test') }
    assert_raises(ArgumentError) { Webgen::Common.append_path('test/', 'test') }
    assert_equal('/', Webgen::Common.append_path('/', '/'))
    assert_equal('/dir', Webgen::Common.append_path('/other', '/dir'))
    assert_equal('/dir/', Webgen::Common.append_path('/other', '/dir/'))
    assert_equal('/other/dir', Webgen::Common.append_path('/other/', 'dir'))
    assert_equal('/test/dir', Webgen::Common.append_path('/other', '../test/dir'))
    assert_equal('/test', Webgen::Common.append_path('/', '/../test'))
    assert_equal('/dir/', Webgen::Common.append_path('/', '/../dir/.'))
  end

end
