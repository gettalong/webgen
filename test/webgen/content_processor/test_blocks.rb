# -*- encoding: utf-8 -*-

require 'helper'
require 'webgen/content_processor/blocks'
require 'webgen/path_handler/page_utils'
require 'webgen/node'
require 'webgen/tree'
require 'webgen/page'
require 'ostruct'

class TestBlocks < MiniTest::Unit::TestCase

  include Test::WebgenAssertions

  class TestHandler
    include Webgen::PathHandler::PageUtils
  end

  class TestNode < Webgen::Node

    def blocks
      node_info[:blocks]
    end

    def render_block(name, context)
      TestHandler.new.render_block(self, name, context)
    end

  end


  def test_static_call_and_render_block
    website = MiniTest::Mock.new
    website.expect(:ext, OpenStruct.new)
    website.ext.item_tracker = MiniTest::Mock.new
    website.ext.item_tracker.expect(:add, nil, [:one, :two, :three])
    website.ext.content_processor = Webgen::ContentProcessor.new
    website.ext.content_processor.register('Blocks')
    website.ext.content_processor.register('Erb')
    obj = Webgen::ContentProcessor::Blocks

    root = TestNode.new(Webgen::Tree.new(website).dummy_root, '/', '/')
    node = TestNode.new(root, 'test', 'test')
    node.node_info[:blocks] = Webgen::Page.from_data("--- name:content\ndata\n--- name:other\nother").blocks
    dnode = TestNode.new(root, 'dtest', 'dtest', {'blocks' => {'content' => {'pipeline' => ['erb']}}})
    dnode.node_info[:blocks] = Webgen::Page.from_data("<%= context.dest_node.alcn %>").blocks
    template = TestNode.new(root, 'template', 'template', {'blocks' => {'content' => {'pipeline' => ['blocks']}}})
    template.node_info[:blocks] = Webgen::Page.from_data("before<webgen:block name='content' />after").blocks

    context = Webgen::Context.new(website)

    context[:chain] = [node]
    context.content = '<webgen:block name="content" /><webgen:block name="content" chain="template;test" />'
    obj.call(context)
    assert_equal('databeforedataafter', context.content)

    context.content = '<webgen:block name="content" node="next" /><webgen:block name="content" chain="template;test" />'
    obj.call(context)
    assert_equal('databeforedataafter', context.content)

    context.content = "\nsadfasdf<webgen:block name='nothing'/>"
    assert_error_on_line(Webgen::RenderError, 2) { obj.call(context) }

    context.content = '<webgen:block name="content" chain="invalid" />'
    assert_error_on_line(Webgen::RenderError, 1) { obj.call(context) }

    context.content = '<webgen:block name="content" />'
    context[:chain] = [node, template, node]
    obj.call(context)
    assert_equal('beforedataafter', context.content)

    # Test correctly set dest_node
    context[:chain] = [node]
    context.content = '<webgen:block name="content" chain="dtest" />'
    obj.call(context)
    assert_equal('/test', context.content)

    context.content = '<webgen:block name="content" chain="dtest" />'
    assert_equal('/test', obj.render_block(context, :chain => [dnode], :name => 'content'))

    context.content = '<webgen:block name="content" chain="dtest" />'
    context[:dest_node] = dnode
    assert_equal('/dtest', obj.render_block(context, :chain => [dnode], :name => 'content'))
    context[:dest_node] = nil

    # Test options "node" and "notfound"
    context[:chain] = [node, template, node]

    context.content = 'bef<webgen:block name="other" chain="template;test" notfound="ignore" />aft'
    obj.call(context)
    assert_equal('befaft', context.content)

    context.content = '<webgen:block name="other" chain="template" node="first" />'
    assert_error_on_line(Webgen::RenderError, 1) { obj.call(context) }

    context.content = '<webgen:block name="other" chain="template;test" node="first" />'
    obj.call(context)
    assert_equal('other', context.content)

    context.content = '<webgen:block name="other" chain="test" node="first" />'
    obj.call(context)
    assert_equal('other', context.content)

    context.content = '<webgen:block name="invalid" node="first" notfound="ignore" /><webgen:block name="content" />'
    obj.call(context)
    assert_equal('beforedataafter', context.content)

    context[:chain] = [node, template]
    context.content = '<webgen:block name="other" node="current" />'
    obj.call(context)
    assert_equal('other', context.content)

    context.content = '<webgen:block name="other" node="current" chain="template"/>'
    obj.call(context)
    assert_equal('other', context.content)

    assert_equal('other', obj.render_block(context, :chain => [template], :name => 'other', :node => 'current'))
    assert_equal('beforedataafter', obj.render_block(context, :chain => [template, node], :name => 'content', :node => 'first'))
  end

end
