# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/node'
require 'webgen/tree'

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

  def test_register_node
    node = Webgen::Node.new(@tree.dummy_root, '/', '/')
    assert_equal(node, @tree['/', :alcn])
    assert_equal(node, @tree['/', :acn])
    assert_equal(node, @tree['/', :dest_path])
    assert_raises(RuntimeError) { Webgen::Node.new(@tree.dummy_root, '/', 'dummy') }
    assert_raises(RuntimeError) { Webgen::Node.new(@tree.dummy_root, 'dummy', '/') }
  end

end
