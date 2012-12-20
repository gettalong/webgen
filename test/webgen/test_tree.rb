# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/tree'

class TestTree < MiniTest::Unit::TestCase

  include Webgen::TestHelper

  def setup
    setup_website
    @tree = @website.tree
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
    setup_default_nodes(@tree)

    assert_equal(@tree['/file.de.html'], @tree.translate_node(@tree['/file.en.html'], 'de'))
    assert_equal(@tree['/file.en.html'], @tree.translate_node(@tree['/file.en.html'], 'en'))
    assert_equal(@tree['/file.en.html'], @tree.translate_node(@tree['/file.de.html'], 'en'))
    assert_equal(nil, @tree.translate_node(@tree['/file.de.html'], 'fr'))
    assert_equal(nil, @tree.translate_node(@tree['/file.en.html'], nil))

    assert_equal(@tree['/other.en.html'], @tree.translate_node(@tree['/other.html'], 'en'))
    assert_equal(@tree['/other.html'], @tree.translate_node(@tree['/other.html'], 'de'))
    assert_equal(@tree['/other.html'], @tree.translate_node(@tree['/other.html'], nil))
    assert_equal(@tree['/other.html'], @tree.translate_node(@tree['/other.en.html'], nil))
    assert_equal(@tree['/other.html'], @tree.translate_node(@tree['/other.en.html'], 'de'))

    assert_equal(nil, @tree.translate_node(@tree['/file.en.html#frag'], nil))
    assert_equal(@tree['/file.en.html#frag'], @tree.translate_node(@tree['/file.en.html#frag'], 'en'))
    assert_equal(@tree['/file.de.html#frag'], @tree.translate_node(@tree['/file.en.html#frag'], 'de'))
  end

  def test_translations
    setup_default_nodes(@tree)

    assert_equal([@tree['/file.en.html'], @tree['/file.de.html']], @tree.translations(@tree['/file.en.html']))
    assert_equal([@tree['/other.html'], @tree['/other.en.html']], @tree.translations(@tree['/other.html']))
  end

  def test_resolve_node
    setup_default_nodes(@tree)

    [@tree['/'], @tree['/file.de.html'], @tree['/file.en.html'], @tree['/other.html']].each do |n|
      assert_equal(nil, n.resolve('file.html', nil))
      assert_equal(@tree['/file.en.html'], n.resolve('file.html', 'en'))
      assert_equal(@tree['/file.de.html'], n.resolve('file.html', 'de'))
      assert_equal(nil, n.resolve('file.html', 'fr'))
      assert_equal(@tree['/file.en.html'], n.resolve('file.en.html', nil))
      assert_equal(@tree['/file.en.html'], n.resolve('file.en.html', 'en'))
      assert_equal(@tree['/file.en.html'], n.resolve('file.en.html', 'de'))
      assert_equal(nil, n.resolve('somename.fr.html', 'de'))

      assert_equal(@tree['/other.html'], n.resolve('other.html', nil))
      assert_equal(@tree['/other.html'], n.resolve('other.html', 'fr'))
      assert_equal(@tree['/other.en.html'], n.resolve('other.html', 'en'))
      assert_equal(@tree['/other.en.html'], n.resolve('other.en.html', nil))
      assert_equal(@tree['/other.en.html'], n.resolve('other.en.html', 'de'))
      assert_equal(nil, n.resolve('other.fr.html', nil))
      assert_equal(nil, n.resolve('other.fr.html', 'en'))
    end

    assert_equal(@tree['/file.en.html#frag'], @tree['/file.en.html'].resolve('#frag', 'de'))
    assert_equal(@tree['/file.en.html#frag'], @tree['/file.en.html'].resolve('#frag', nil))
    assert_equal(@tree['/file.en.html#nested'], @tree['/file.en.html'].resolve('#nested', nil))

    assert_equal(nil, @tree.resolve_node('/file.html#frag', nil))
    assert_equal(@tree['/file.en.html#frag'], @tree.resolve_node('/file.html#frag', 'en'))
    assert_equal(@tree['/file.de.html#frag'], @tree.resolve_node('/file.html#frag', 'de'))
    assert_equal(@tree['/file.en.html#frag'], @tree.resolve_node('/file.en.html#frag', nil))
    assert_equal(@tree['/file.de.html#frag'], @tree.resolve_node('/file.de.html#frag', nil))

    assert_equal(@tree['/dir2/index.en.html'], @tree['/dir2/'].resolve('index.en.html'))
    assert_equal(@tree['/other.html'], @tree['/'].resolve('other.html'))

    assert_equal(@tree['/dir/'], @tree['/file.en.html'].resolve('/dir/'))
    assert_equal(@tree['/dir/'], @tree['/file.en.html'].resolve('/dir'))
    assert_equal(@tree['/'], @tree['/file.en.html'].resolve('/'))

    nrcalls = 0
    @website.blackboard.add_listener(:node_resolution_failed) { nrcalls += 1 }
    assert_equal(nil, @tree['/'].resolve('other.fr.html', nil, false))
    assert_equal(0, nrcalls)
    assert_equal(nil, @tree['/'].resolve('other.fr.html', nil, true))
    assert_equal(1, nrcalls)
  end

  def test_register_node
    node = Webgen::Node.new(@tree.dummy_root, '/', '/')
    assert_equal(node, @tree.node('/', :alcn))
    assert_equal(node, @tree.node('/', :acn))
    assert_equal(node, @tree.node('/', :dest_path))

    other_node = Webgen::Node.new(node, 'dummy.html', '/', 'no_output' => true)
    assert_equal('/', other_node.dest_path)

    assert_raises(RuntimeError) { Webgen::Node.new(@tree.dummy_root, '/', 'dummy') }
    assert_raises(RuntimeError) { Webgen::Node.new(@tree.dummy_root, 'dummy', '/') }
  end

  def test_delete_node
    nrcalls = 0
    @website.blackboard.add_listener(:before_node_deleted) { nrcalls += 1 }

    root = Webgen::Node.new(@tree.dummy_root, '/', '/')
    file = Webgen::Node.new(root, 'testfile', 'testfile')
    dir = Webgen::Node.new(root, 'testdir/', 'testdir')
    virtual_root = Webgen::Node.new(root, 'vroot', '/', 'no_output' => true)

    @tree.delete_node(@tree.dummy_root)
    refute_nil(@tree[''])

    assert_nil(@tree.delete_node('/unknown_path'))

    @tree.delete_node(file)
    assert_nil(@tree['/testfile'])
    assert_nil(@tree.node('/testfile', :acn))
    assert_nil(@tree.node('/testfile', :dest_path))
    assert_equal(0, @tree.node_access[:translation_key]['/testfile'].length)
    assert_equal(2, root.children.size)
    assert_equal(1, nrcalls)

    @tree.delete_node(virtual_root)
    assert_equal(root, @tree.node('/', :dest_path))

    @tree.delete_node(root)
    assert_nil(@tree['/testdir'])
    assert_nil(@tree.node('/testdir', :acn))
    assert_nil(@tree.node('/testdir', :dest_path))
    assert_nil(@tree['/'])
    assert_equal(4, nrcalls)
    assert_equal([@tree.dummy_root], @tree.node_access[:alcn].values)
  end

end
