require 'test/unit'
require 'helper'
require 'webgen/tree'

class TestTree < Test::Unit::TestCase

  include Test::WebsiteHelper

  def setup
    super
    @tree = Webgen::Tree.new
  end

  def test_initialize
    assert_not_nil(@tree.dummy_root)
  end

  def test_root
    root = Webgen::Node.new(@tree.dummy_root, '/', '/')
    assert_equal(root, @tree.root)
  end

  def test_register_node
    # Tree#register_node is called when creating a node
    node = Webgen::Node.new(@tree.dummy_root, 'dummy/', 'dummy')
    assert_equal(node, @tree['/dummy', :alcn])
    assert_equal(node, @tree['/dummy', :acn])
    assert_equal(node, @tree['dummy/', :path])
    assert_raise(RuntimeError) { Webgen::Node.new(@tree.dummy_root, '/', 'dummy') }
    assert_raise(RuntimeError) { Webgen::Node.new(@tree.dummy_root, 'dummy/', 'other') }
  end

  def test_delete_node
    nrcalls = 0
    @website.blackboard.add_listener(:before_node_deleted) { nrcalls += 1 }

    root = Webgen::Node.new(@tree.dummy_root, '/', '/')
    file = Webgen::Node.new(root, 'testfile', 'testfile')
    dir = Webgen::Node.new(root, 'testdir/', 'testdir')

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

    Webgen::Node.new(root, 'testfile', 'testfile')
    Webgen::Node.new(root, 'testdir/', 'testdir')
    @tree.delete_node(root, true)
    assert_equal([@tree.dummy_root], @tree.node_access[:alcn].values)
  end

end
