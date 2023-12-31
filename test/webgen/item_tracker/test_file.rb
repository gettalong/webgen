# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'time'
require 'webgen/item_tracker/file'

class TestItemTrackerFile < Minitest::Test

  def setup
    @website = Minitest::Mock.new
    @obj = Webgen::ItemTracker::File.new(@website)
  end

  def test_item_id
    assert_equal('filename', @obj.item_id('filename'))
  end

  def test_item_data
    assert_equal(File.mtime(__FILE__), @obj.item_data(__FILE__))
  end

  def test_item_changed?
    refute(@obj.item_changed?(__FILE__, Time.now))
    assert(@obj.item_changed?(__FILE__, Time.parse("1980-01-01")))
  end

  def test_referenced_nodes
    assert_equal([], @obj.referenced_nodes('anything', 'nothing'))
  end

end
