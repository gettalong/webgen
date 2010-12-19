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
    @website.expect(:tree, {'alcn' => {'modified_at' => 'now'}})
    assert_equal('now', @obj.item_data('alcn'))
    @website.verify
  end

  def test_changed?
    @website.expect(:tree, {'alcn' => {'modified_at' => 'now'}})
    assert(@obj.changed?('unknown', 'old'))
    assert(@obj.changed?('alcn', 'other'))
    @website.verify
  end

end
