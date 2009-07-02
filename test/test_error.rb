# -*- encoding: utf-8 -*-

require 'test/unit'
require 'webgen/error'

class TestError < Test::Unit::TestCase

  def test_all
    e = Webgen::Error.new("test")
    assert_equal("test", e.message)
    assert_match(/Error while working:/, e.pretty_message)

    e = Webgen::Error.new("test", 'KlassName')
    assert_equal("test", e.message)
    assert_equal('KlassName', e.class_name)
    assert_match(/Error while working with KlassName:/, e.pretty_message)

    e = Webgen::Error.new("test", 'KlassName', '/path')
    assert_equal("test", e.message)
    assert_equal('KlassName', e.class_name)
    assert_equal('/path', e.alcn)
    assert_match(/Error while working on <\/path> with KlassName:/, e.pretty_message)
  end

end

class TestNodeCreationError < Test::Unit::TestCase

  def test_all
    e = Webgen::NodeCreationError.new("test")
    assert_equal("test", e.message)
    assert_match(/Error while creating a node:/, e.pretty_message)
  end

end

class TestRenderError < Test::Unit::TestCase

  def test_all
    e = Webgen::RenderError.new("test", 'KlassName', '/path', '/error')
    assert_equal("/error", e.error_alcn)
    assert_match(/Error in <\/error> while rendering <\/path>/, e.pretty_message)

    e = Webgen::RenderError.new("test", 'KlassName', '/path', '/error', 5)
    assert_equal("/error", e.error_alcn)
    assert_match(/Error in <\/error:~5> while rendering <\/path>/, e.pretty_message)
  end

end
