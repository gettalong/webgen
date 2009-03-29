# -*- encoding: utf-8 -*-

require 'test/unit'
require 'webgen/tree'
require 'webgen/page'
require 'webgen/contentprocessor'

class TestContentProcessorBlocks < Test::Unit::TestCase

  def test_process
    obj = Webgen::ContentProcessor::Blocks.new
    root = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/')
    node = Webgen::Node.new(root, 'test', 'test')
    node.node_info[:page] = Webgen::Page.from_data("--- name:content\ndata\n--- name:other\nother")
    template = Webgen::Node.new(root, 'template', 'template')
    template.node_info[:page] = Webgen::Page.from_data("--- name:content pipeline:blocks\nbefore<webgen:block name='content' />after")
    processors = { 'blocks' => obj }

    context = Webgen::ContentProcessor::Context.new(:chain => [node], :processors => processors)
    context.content = '<webgen:block name="content" /><webgen:block name="content" chain="template;test" />'
    obj.call(context)
    assert_equal('databeforedataafter', context.content)
    assert_equal(Set.new([node.absolute_lcn, template.absolute_lcn]), node.node_info[:used_nodes])

    context.content = '<webgen:block name="content" node="next" /><webgen:block name="content" chain="template;test" />'
    obj.call(context)
    assert_equal('databeforedataafter', context.content)

    context.content = '<webgen:block name="nothing"/>'
    assert_raise(RuntimeError) { obj.call(context) }

    context.content = '<webgen:block name="content" chain="invalid" /><webgen:block name="content" />'
    node.node_info[:used_nodes] = Set.new
    context[:chain] = [node, template, node]
    obj.call(context)
    assert_equal('<webgen:block name="content" chain="invalid" />beforedataafter', context.content)
    assert_equal(Set.new([template.absolute_lcn, node.absolute_lcn]), node.node_info[:used_nodes])

    context.content = 'bef<webgen:block name="other" chain="template;test" notfound="ignore" />aft'
    obj.call(context)
    assert_equal('befaft', context.content)

    context.content = '<webgen:block name="other" chain="template" node="first" />'
    assert_raise(RuntimeError) { obj.call(context) }

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
  end

end
