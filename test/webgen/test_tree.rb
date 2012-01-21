# -*- encoding: utf-8 -*-

require 'helper'
require 'webgen/node'
require 'webgen/tree'
require 'webgen/blackboard'

class TestTree < MiniTest::Unit::TestCase

  def setup
    @website = MiniTest::Mock.new
    @tree = Webgen::Tree.new(@website)
  end

  def test_initialize
    refute_equal(nil, @tree.dummy_root)
    assert_equal('', @tree.dummy_root.alcn)
  end

  def test_root
    root = Webgen::Node.new(@tree.dummy_root, '/', '/')
    assert_equal(root, @tree.root)
    assert_equal('/', root.alcn)
  end

  def test_translate_node
    nodes = Test.create_default_nodes(@tree)

    assert_equal(nodes[:somename_de], @tree.translate_node(nodes[:somename_en], 'de'))
    assert_equal(nodes[:somename_en], @tree.translate_node(nodes[:somename_en], 'en'))
    assert_equal(nodes[:somename_en], @tree.translate_node(nodes[:somename_de], 'en'))
    assert_equal(nil, @tree.translate_node(nodes[:somename_de], 'fr'))
    assert_equal(nil, @tree.translate_node(nodes[:somename_en], nil))

    assert_equal(nodes[:other_en], @tree.translate_node(nodes[:other], 'en'))
    assert_equal(nodes[:other], @tree.translate_node(nodes[:other], 'de'))
    assert_equal(nodes[:other], @tree.translate_node(nodes[:other], nil))
    assert_equal(nodes[:other], @tree.translate_node(nodes[:other_en], nil))
    assert_equal(nodes[:other], @tree.translate_node(nodes[:other_en], 'de'))

    assert_equal(nil, @tree.translate_node(nodes[:somename_en_frag], nil))
    assert_equal(nodes[:somename_en_frag], @tree.translate_node(nodes[:somename_en_frag], 'en'))
    assert_equal(nodes[:somename_de_frag], @tree.translate_node(nodes[:somename_en_frag], 'de'))
  end

  def test_translations
    nodes = Test.create_default_nodes(@tree)

    assert_equal([nodes[:somename_en], nodes[:somename_de]], @tree.translations(nodes[:somename_en]))
    assert_equal([nodes[:other], nodes[:other_en]], @tree.translations(nodes[:other]))
  end

  def test_resolve_node
    nodes = Test.create_default_nodes(@tree)

    [nodes[:root], nodes[:somename_de], nodes[:somename_en], nodes[:other]].each do |n|
      assert_equal(nil, n.resolve('somename.html', nil))
      assert_equal(nodes[:somename_en], n.resolve('somename.html', 'en'))
      assert_equal(nodes[:somename_de], n.resolve('somename.html', 'de'))
      assert_equal(nil, n.resolve('somename.html', 'fr'))
      assert_equal(nodes[:somename_en], n.resolve('somename.en.html', nil))
      assert_equal(nodes[:somename_en], n.resolve('somename.en.html', 'en'))
      assert_equal(nodes[:somename_en], n.resolve('somename.en.html', 'de'))
      assert_equal(nil, n.resolve('somename.fr.html', 'de'))

      assert_equal(nodes[:other], n.resolve('other.html', nil))
      assert_equal(nodes[:other], n.resolve('other.html', 'fr'))
      assert_equal(nodes[:other_en], n.resolve('other.html', 'en'))
      assert_equal(nodes[:other_en], n.resolve('other.en.html', nil))
      assert_equal(nodes[:other_en], n.resolve('other.en.html', 'de'))
      assert_equal(nil, n.resolve('other.fr.html', nil))
      assert_equal(nil, n.resolve('other.fr.html', 'en'))
    end

    assert_equal(nodes[:somename_en_frag], nodes[:somename_en].resolve('#othertest', 'de'))
    assert_equal(nodes[:somename_en_frag], nodes[:somename_en].resolve('#othertest', nil))
    assert_equal(nodes[:somename_en_fragnest], nodes[:somename_en].resolve('#nestedpath', nil))

    assert_equal(nil, @tree.resolve_node('/somename.html#othertest', nil))
    assert_equal(nodes[:somename_en_frag], @tree.resolve_node('/somename.html#othertest', 'en'))
    assert_equal(nodes[:somename_de_frag], @tree.resolve_node('/somename.html#othertest', 'de'))
    assert_equal(nodes[:somename_en_frag], @tree.resolve_node('/somename.en.html#othertest', nil))
    assert_equal(nodes[:somename_de_frag], @tree.resolve_node('/somename.de.html#othertest', nil))

    assert_equal(nodes[:dir2_index_en], nodes[:dir2].resolve('index.html'))
    assert_equal(nodes[:other_en], nodes[:root].resolve('other1.html'))

    assert_equal(nodes[:dir], nodes[:somename_en].resolve('/dir/'))
    assert_equal(nodes[:dir], nodes[:somename_en].resolve('/dir'))
    assert_equal(nodes[:root], nodes[:somename_en].resolve('/'))
  end

  def test_register_node
    node = Webgen::Node.new(@tree.dummy_root, '/', '/')
    assert_equal(node, @tree['/', :alcn])
    assert_equal(node, @tree['/', :acn])
    assert_equal(node, @tree['/', :dest_path])
    assert_raises(RuntimeError) { Webgen::Node.new(@tree.dummy_root, '/', 'dummy') }
    assert_raises(RuntimeError) { Webgen::Node.new(@tree.dummy_root, 'dummy', '/') }
  end

  def test_delete_node
    nrcalls = 0
    blackboard = Webgen::Blackboard.new
    @website.expect(:blackboard, blackboard)
    blackboard.add_listener(:before_node_deleted) { nrcalls += 1 }

    root = Webgen::Node.new(@tree.dummy_root, '/', '/')
    file = Webgen::Node.new(root, 'testfile', 'testfile')
    dir = Webgen::Node.new(root, 'testdir/', 'testdir')

    @tree.delete_node(@tree.dummy_root)
    refute_nil(@tree[''])

    assert_nil(@tree.delete_node('/unknown_path'))

    @tree.delete_node(file)
    assert_nil(@tree['/testfile'])
    assert_nil(@tree['/testfile', :acn])
    assert_nil(@tree['/testfile', :dest_path])
    assert_equal(0, @tree.node_access[:translation_key]['/testfile'].length)
    assert_equal(1, root.children.size)
    assert_equal(1, nrcalls)

    @tree.delete_node(root)
    assert_nil(@tree['/testdir'])
    assert_nil(@tree['/testdir', :acn])
    assert_nil(@tree['/testdir', :dest_path])
    assert_nil(@tree['/'])
    assert_equal(3, nrcalls)
    assert_equal([@tree.dummy_root], @tree.node_access[:alcn].values)
  end

end
