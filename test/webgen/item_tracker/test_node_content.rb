# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/item_tracker/node_content'

class TestNodeContent < MiniTest::Unit::TestCase

  def setup
    @website = MiniTest::Mock.new
    @obj = Webgen::ItemTracker::NodeContent.new(@website)
  end

  def test_item_id
    assert_equal('id', @obj.item_id('id'))
  end

  def test_item_data
    assert_nil(@obj.item_data('alcn'))
  end

  def test_item_changed?
    item_tracker = MiniTest::Mock.new
    item_tracker.expect(:node_changed?, true, [:node])
    ext = MiniTest::Mock.new
    ext.expect(:item_tracker, item_tracker)
    @website.expect(:ext, ext)
    @website.expect(:tree, {'alcn' => :node})

    assert(@obj.item_changed?('unknown', 'old'))
    assert(@obj.item_changed?('alcn', 'other'))

    @website.verify
    item_tracker.verify
    ext.verify
  end

  def test_node_referenced?
    assert(@obj.node_referenced?('alcn', nil, 'alcn'))
    refute(@obj.node_referenced?('other', nil, 'alcn'))
  end

end
