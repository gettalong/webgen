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
    assert_equal('', @tree.dummy_root.absolute_lcn)
  end

  def test_root
    root = Webgen::Node.new(@tree.dummy_root, '/', '/')
    assert_equal(root, @tree.root)
    assert_equal('/', root.absolute_lcn)
  end

  def test_register_node_and_register_path
    # Tree#register_node/_path is called when creating a node
    node = Webgen::Node.new(@tree.dummy_root, 'dummy/', 'dummy')
    assert_equal(node, @tree['/dummy', :alcn])
    assert_equal(node, @tree['/dummy', :acn])
    assert_equal(node, @tree['dummy/', :path])
    assert_raise(RuntimeError) { Webgen::Node.new(@tree.dummy_root, '/', 'dummy') }
    assert_raise(RuntimeError) { Webgen::Node.new(@tree.dummy_root, 'dummy/', 'other') }
    assert_nothing_raised { Webgen::Node.new(@tree.dummy_root, 'dummy/', 'unknown', {'no_output' => true}) }
    Webgen::Node.new(@tree.dummy_root, 'new', 'new', {'no_output' => true})
    assert(!@tree['new', :path])
  end

  def test_delete_node
    nrcalls = 0
    @website.blackboard.add_listener(:before_node_deleted) { nrcalls += 1 }

    root = Webgen::Node.new(@tree.dummy_root, '/', '/')
    file = Webgen::Node.new(root, 'testfile', 'testfile')
    dir = Webgen::Node.new(root, 'testdir/', 'testdir')

    @tree.delete_node(@tree.dummy_root)
    assert_not_nil(@tree[''])

    assert_nothing_raised { @tree.delete_node('/unknown_path') }

    @tree.delete_node(file)
    assert_nil(@tree['/testfile'])
    assert_nil(@tree['/testfile', :acn])
    assert_nil(@tree.node_info['/testfile'])
    assert_equal(1, root.children.size)
    assert_equal(1, nrcalls)

    @tree.delete_node('/')
    assert_nil(@tree['/testdir'])
    assert_nil(@tree['/testdir', :acn])
    assert_nil(@tree.node_info['/testdir'])
    assert_nil(@tree['/'])
    assert_nil(@tree.node_info['/'])
    assert_equal(3, nrcalls)
    assert_equal([@tree.dummy_root], @tree.node_access[:alcn].values)
  end

end
