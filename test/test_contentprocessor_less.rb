# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/tree'
require 'webgen/contentprocessor'

class TestContentProcessorLess < Test::Unit::TestCase

  include Test::WebgenAssertions

  def test_call
    obj = Webgen::ContentProcessor::Less.new
    root = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/')
    node = Webgen::Node.new(root, 'test', 'test')
    context = Webgen::Context.new(:content => "div {width: 1 + 1}",
                                  :chain => [node])
    obj.call(context)
    assert_equal("div { width: 2; }\n", context.content)

    context.content = ".class {color: yellow}\ndiv {width: 1 + }"
    assert_error_on_line(Webgen::RenderError, 2) { obj.call(context) }

    context.content = "div { width: 2em + 1px; }"
    assert_raise(Webgen::RenderError) { obj.call(context) }

    context.content = "div {width: @hallo + 1}"
    assert_raise(Webgen::RenderError) { obj.call(context) }

    context.content = "div {width: 1px; .mixin;}"
    assert_raise(Webgen::RenderError) { obj.call(context) }

    context.content = "@import \"hallo\";"
    assert_raise(Webgen::RenderError) { obj.call(context) }

    def obj.require(lib); raise LoadError; end
    assert_raise(Webgen::LoadError) { obj.call(context) }
  end

end
