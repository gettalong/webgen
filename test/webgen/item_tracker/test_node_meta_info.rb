# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/item_tracker/node_meta_info'

class TestNodeMetaInfo < MiniTest::Unit::TestCase

  def setup
    @website = MiniTest::Mock.new
    @node = MiniTest::Mock.new
    @node.expect(:meta_info, {'key' => 'value'})
    @website.expect(:tree, {'alcn' => @node})
    @obj = Webgen::ItemTracker::NodeMetaInfo.new(@website)
  end

  def test_item_id
    assert_equal(['id', nil], @obj.item_id('id'))
    assert_equal(['id', 'key'], @obj.item_id('id', 'key'))
  end

  def test_item_data
    assert_equal({'key' => 'value'}, @obj.item_data('alcn'))
    refute_same(@node.meta_info, @obj.item_data('alcn'))
    assert_equal('value', @obj.item_data('alcn', 'key'))
    refute_same(@node.meta_info['key'], @obj.item_data('alcn', 'key'))
    @website.verify
    @node.verify
  end

  def test_item_changed?
    @node.expect(:nil?, false)
    assert(@obj.item_changed?(['unknown', nil], 'old'))
    assert(@obj.item_changed?(['alcn', nil], {"key" => 'value', 'other' => 'new'}))
    assert(@obj.item_changed?(['alcn', 'key'], 'new'))
    @website.verify
    @node.verify
  end

  def test_referenced_nodes
    assert_equal(['alcn'], @obj.referenced_nodes(['alcn', nil], 'mi'))
  end

end
