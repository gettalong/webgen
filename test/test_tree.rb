require 'test/unit'
require 'helper'
require 'webgen/tree'

class TestTree < Test::Unit::TestCase

  include Test::WebsiteHelper

  def test_initialize
    @tree = Webgen::Tree.new
    assert_not_nil(@tree.dummy_root)
  end

  def test_root
    @tree = Webgen::Tree.new
    root = Webgen::Node.new(@tree.dummy_root, '/')
    assert_equal(root, @tree.root)
  end

  def test_delete_node
    nrcalls = 0
    @website.blackboard.add_listener(:before_node_deleted) { nrcalls += 1 }

    @tree = Webgen::Tree.new
    root = Webgen::Node.new(@tree.dummy_root, '/')
    file = Webgen::Node.new(root, 'testfile')
    dir = Webgen::Node.new(root, 'testdir/')

    @tree.delete_node(@tree.dummy_root)
    assert_not_nil(@tree[''])

    @tree.delete_node(root)
    assert_not_nil(@tree['/'])

    @tree.delete_node(file)
    assert_nil(@tree['/testfile'])
    assert_nil(@tree['/testfile', :acn])
    assert_nil(@tree.node_info['/testfile'])
    assert_equal(1, root.children.size)
    assert_equal(1, nrcalls)

    @tree.delete_node('/', true)
    assert_nil(@tree['/testdir'])
    assert_nil(@tree['/testdir', :acn])
    assert_nil(@tree.node_info['/testdir'])
    assert_nil(@tree['/'])
    assert_nil(@tree.node_info['/'])
    assert_equal(3, nrcalls)
  end

end
