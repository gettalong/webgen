# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/tree'
require 'webgen/contentprocessor'

class TestContentProcessorHaml < Test::Unit::TestCase

  include Test::WebgenAssertions

  def test_call
    obj = Webgen::ContentProcessor::Haml.new
    root = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/')
    node = Webgen::Node.new(root, 'test', 'test')
    content = "#content\n  %h1 Hallo\n  = [context.node.alcn, context.ref_node.alcn, context.dest_node.alcn, context.website, context.dest_node.alcn].join"
    context = Webgen::Context.new(:content => content,
                                                    :chain => [node])
    obj.call(context)
    assert_equal("<div id='content'>\n  <h1>Hallo</h1>\n  /test/test/test/test\n</div>\n", context.content)

    context.content = "#cont\n    % = + unknown"
    assert_error_on_line(Webgen::RenderError, 2) { obj.call(context) }

    context.content = "#cont\n  = unknown"
    assert_error_on_line(Webgen::RenderError, 2) { obj.call(context) }

    def obj.require(lib); raise LoadError; end
    assert_raise(Webgen::LoadError) { obj.call(context) }
  end

end
