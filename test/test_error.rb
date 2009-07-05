# -*- encoding: utf-8 -*-

require 'test/unit'
require 'webgen/error'

class TestError < Test::Unit::TestCase

  def test_all
    e = Webgen::Error.new("test")
    assert_equal("test", e.plain_message)
    assert_match(/Error while working:/, e.message)

    e = Webgen::Error.new("test", 'KlassName')
    assert_equal("test", e.plain_message)
    assert_equal('KlassName', e.class_name)
    assert_match(/Error while working with KlassName:/, e.message)

    e = Webgen::Error.new("test", 'KlassName', '/path')
    assert_equal("test", e.plain_message)
    assert_equal('KlassName', e.class_name)
    assert_equal('/path', e.alcn)
    assert_match(/Error while working on <\/path> with KlassName:/, e.message)

    e = Webgen::Error.new(Exception.new("test"))
    assert_equal("test", e.plain_message)
    assert_match(/Error while working:/, e.message)
  end

end

class TestNodeCreationError < Test::Unit::TestCase

  def test_all
    e = Webgen::NodeCreationError.new("test")
    assert_equal("test", e.plain_message)
    assert_match(/Error while creating a node:/, e.message)
  end

end

class TestRenderError < Test::Unit::TestCase

  def test_all
    e = Webgen::RenderError.new("test", 'KlassName', '/path', '/error')
    assert_equal("/error", e.error_alcn)
    assert_match(/Error in <\/error> while rendering <\/path>/, e.message)

    e = Webgen::RenderError.new("test", 'KlassName', '/path', '/error', 5)
    assert_equal("/error", e.error_alcn)
    assert_match(/Error in <\/error:~5> while rendering <\/path>/, e.message)
  end

end

class TestLoadError < Test::Unit::TestCase

  def test_all
    e = Webgen::LoadError.new(Exception.new("something"), 'KlassName', '/path')
    assert_nil(e.library)
    assert_nil(e.gem)
    assert_match(/Error while working on <\/path> with KlassName:.*something/m, e.message)

    e = Webgen::LoadError.new("test", 'KlassName', '/path')
    assert_equal("test", e.library)
    assert_nil(e.gem)
    assert_match(/Error while working on <\/path> with KlassName:.*The needed library 'test' is missing/m, e.message)

    e = Webgen::LoadError.new("test", 'KlassName', '/path', 'gem')
    assert_equal("test", e.library)
    assert_equal('gem', e.gem)
    assert_match(/Error while working on <\/path> with KlassName:.*The needed library 'test' is missing.*gem install gem/m, e.message)
  end

end


class TestCommandNotFoundError < Test::Unit::TestCase

  def test_all
    e = Webgen::CommandNotFoundError.new("test", 'KlassName', '/path')
    assert_equal("test", e.cmd)
    assert_match(/Error while working on <\/path> with KlassName:.*The needed command 'test' is missing/m, e.message)
  end

end
