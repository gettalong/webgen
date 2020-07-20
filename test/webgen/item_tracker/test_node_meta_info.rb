# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/item_tracker/node_meta_info'

class TestNodeMetaInfo < Minitest::Test

  def setup
    @website = Object.new
    @node = node = Object.new
    @meta_info_data = meta_info_data = {'key' => 'value'}
    @node.define_singleton_method(:meta_info) { meta_info_data }
    @website.define_singleton_method(:tree) { {'alcn' => node} }
    @obj = Webgen::ItemTracker::NodeMetaInfo.new(@website)
  end

  def test_item_id
    @node.define_singleton_method(:alcn) { 'id' }
    assert_equal(['id', nil], @obj.item_id(@node))
    assert_equal(['id', 'key'], @obj.item_id(@node, 'key'))
  end

  def test_item_data
    assert_equal({'key' => 'value'}, @obj.item_data('alcn'))
    refute_same(@node.meta_info, @obj.item_data('alcn'))
    assert_equal('value', @obj.item_data('alcn', 'key'))
    refute_same(@node.meta_info['key'], @obj.item_data('alcn', 'key'))

    @meta_info_data['modified_at'] = 5
    assert_equal({'key' => 'value'}, @obj.item_data('alcn'))
    @meta_info_data['modified_at_in_dest_path'] = true

    assert_equal({'key' => 'value', 'modified_at' => 5, 'modified_at_in_dest_path' => true},
                 @obj.item_data('alcn'))
  end

  def test_item_changed?
    assert(@obj.item_changed?(['unknown', nil], 'old'))
    assert(@obj.item_changed?(['alcn', nil], {"key" => 'value', 'other' => 'new'}))
    assert(@obj.item_changed?(['alcn', 'key'], 'new'))
  end

  def test_referenced_nodes
    assert_equal(['alcn'], @obj.referenced_nodes(['alcn', nil], 'mi'))
  end

end
