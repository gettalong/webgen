# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/page'
require 'webgen/tree'
require 'webgen/contentprocessor'

class TestContentProcessorFragments < Test::Unit::TestCase

  include Test::WebsiteHelper

  def test_process
    Webgen::SourceHandler::Main.new
    @website.blackboard.del_service(:source_paths)
    @website.blackboard.add_service(:source_paths) { Hash.new(path_with_meta_info('/test.html')) }

    obj = Webgen::ContentProcessor::Fragments.new
    root = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/')
    node = Webgen::Node.new(root, '/test.html', 'test.html')
    node.node_info[:src] = '/test.html'
    processors = { 'fragments' => obj }

    context = Webgen::Context.new(:chain => [node], :processors => processors)
    context.content = '<h1 id="test">Test</h1><h1>Test2</h1>'
    obj.call(context)
    assert(root.tree['/test.html#test'])
    assert_equal(4, root.tree.node_access[:alcn].length)
    root.tree.delete_node('/test.html#test')

    context[:block] = Webgen::Page::Block.new('content', '', {})
    obj.call(context)
    assert(root.tree['/test.html#test'])
    assert_equal(4, root.tree.node_access[:alcn].length)
    root.tree.delete_node('/test.html#test')

    context[:block] = Webgen::Page::Block.new('other', '', {})
    obj.call(context)
    assert(!root.tree['/test.html#test'])
    assert_equal(3, root.tree.node_access[:alcn].length)
  end

end
