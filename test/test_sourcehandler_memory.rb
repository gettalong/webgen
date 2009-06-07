# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/sourcehandler'
require 'stringio'

class TestSourceHandlerMemory < Test::Unit::TestCase

  include Test::WebsiteHelper

  def test_all
    obj = Webgen::SourceHandler::Memory.new
    root = Webgen::Node.new(@website.tree.dummy_root, '/', '/')
    shm = Webgen::SourceHandler::Main.new # for using service :create_nodes
    root.unflag(:dirty)
    root.unflag(:created)

    node = obj.create_node(path_with_meta_info('/test.png'), '/', 'data')
    assert_equal('/', node.node_info[:memory_source_alcn])
    assert_equal('data', obj.content(node))
    assert(!node.flagged?(:reinit))
    root.tree.delete_node(node)

    node = obj.create_node(path_with_meta_info('/test.png'), '/') {|n| assert_equal(node, n); 'data'}
    assert_equal('/', node.node_info[:memory_source_alcn])
    assert_equal('data', obj.content(node))
    assert(!node.flagged?(:reinit))

    assert(!root.flagged?(:dirty))
    node.flag(:reinit)
    assert(root.flagged?(:dirty))
    root.unflag(:dirty)
    root.tree.delete_node(node)

    node = obj.create_node(path_with_meta_info('/test.png'), '/', 'data')
    assert_equal('/', node.node_info[:memory_source_alcn])
    obj.instance_eval { @data = nil }
    assert_nil(obj.content(node))
    assert(node.flagged?(:reinit))
    assert(root.flagged?(:dirty))
  end

end
