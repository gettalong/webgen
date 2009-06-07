# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/tree'
require 'webgen/contentprocessor'

class TestContentProcessorBuilder < Test::Unit::TestCase

  def test_call
    obj = Webgen::ContentProcessor::Builder.new
    root = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/')
    node = Webgen::Node.new(root, 'test', 'test')
    content = "xml.div(:path => context.node.alcn) { xml.strong('test'); " +
      "context.website; context; context.ref_node; context.dest_node }"
    context = Webgen::Context.new(:content => content,
                                                    :chain => [node])
    assert_equal("<div path=\"/test\">\n  <strong>test</strong>\n</div>\n", obj.call(context).content)

    context.content = 'raise "bla"'
    assert_raise(RuntimeError) { obj.call(context).content }
  end

end
