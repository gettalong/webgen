require 'test/unit'
require 'webgen/tree'


require 'webgen/blackboard'
class DummyWebsite
  attr_reader :blackboard

  def initialize
    @blackboard = Webgen::Blackboard.new
  end
end


class TestTree < Test::Unit::TestCase

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
    website = Thread.current[:webgen_website] = DummyWebsite.new
    nrcalls = 0
    website.blackboard.add_listener(:before_node_deleted) { nrcalls += 1 }

    @tree = Webgen::Tree.new
    root = Webgen::Node.new(@tree.dummy_root, '/')
    file = Webgen::Node.new(root, 'testfile')
    dir = Webgen::Node.new(root, 'testdir/')

    @tree.delete_node(@tree.dummy_root)
    assert_not_nil(@tree.node_access[''])

    @tree.delete_node(root)
    assert_not_nil(@tree.node_access['/'])

    @tree.delete_node(file)
    assert_nil(@tree.node_access['/testfile'])
    assert_nil(@tree.node_info['/testfile'])
    assert_equal(1, root.children.size)
    assert_equal(1, nrcalls)

    @tree.delete_node('/', true)
    assert_nil(@tree.node_access['/testdir'])
    assert_nil(@tree.node_info['/testdir'])
    assert_nil(@tree.node_access['/'])
    assert_nil(@tree.node_info['/'])
    assert_equal(3, nrcalls)

    Thread.current[:webgen_website] = nil
  end

end
