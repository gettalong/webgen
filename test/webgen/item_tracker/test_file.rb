# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'time'
require 'webgen/item_tracker/file'

class TestItemTrackerFile < MiniTest::Unit::TestCase

  def setup
    @website = MiniTest::Mock.new
    @obj = Webgen::ItemTracker::File.new(@website)
  end

  def test_item_id
    assert_equal('filename', @obj.item_id('filename'))
  end

  def test_item_data
    assert_equal(File.mtime(__FILE__), @obj.item_data(__FILE__))
  end

  def test_changed?
    refute(@obj.changed?(__FILE__, Time.now))
    assert(@obj.changed?(__FILE__, Time.parse("1980-01-01")))
  end

  def test_node_referenced?
    refute(@obj.node_referenced?('anything', 'nothing', '/alcn'))
  end

end
