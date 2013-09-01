# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/item_tracker/node_content'

class TestNodeContent < Minitest::Test

  def setup
    @website = Object.new
    @obj = Webgen::ItemTracker::NodeContent.new(@website)
  end

  def test_item_id
    s = 'id'
    def s.alcn; self; end
    assert_equal('id', @obj.item_id(s))
  end

  def test_item_data
    assert_nil(@obj.item_data('alcn'))
  end

  def test_item_changed?
    ext = OpenStruct.new
    ext.item_tracker = Object.new
    ext.item_tracker.define_singleton_method(:node_changed?) {|n| raise unless n == :node; true}
    @website.define_singleton_method(:ext) { ext }
    @website.define_singleton_method(:tree) { {'alcn' => :node} }

    assert(@obj.item_changed?('unknown', 'old'))
    assert(@obj.item_changed?('alcn', 'other'))
  end

  def test_referenced_nodes
    assert_equal(['alcn'], @obj.referenced_nodes('alcn', nil))
  end

end
