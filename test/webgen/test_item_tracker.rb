# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/item_tracker'
require 'webgen/blackboard'

class Webgen::ItemTracker::Sample

  def initialize(website) #:nodoc:
    @website = website
  end

  def item_id(data) #:nodoc:
    data
  end

  def item_data(data) #:nodoc:
    'alcn' + data
  end

  def changed?(iid, old_data) #:nodoc:
    'alcn' + iid != old_data
  end

end

class TestItemTracker < MiniTest::Unit::TestCase

  def setup
    @tracker = Webgen::ItemTracker.new
    @tracker.register('Sample')
  end

  def test_functionality
    # Needed mock objects
    website = MiniTest::Mock.new
    website.expect(:blackboard, blackboard = Webgen::Blackboard.new)
    website.expect(:cache, cache = {})
    node = MiniTest::Mock.new
    node.expect(:alcn, '/alcn')

    @tracker.website = website
    @tracker.add(node, :sample, 'mydata')

    # Item should be changed because no cache data is available
    assert(@tracker.send(:item_changed?, @tracker.send(:unique_id, :sample, 'mydata')))

    # Test the initial loading of the cache data
    cache[:item_tracker_data] = {
      :node_dependencies => {'alcn' => ['data']},
      :item_data => {[:sample, 'mydata'] => 'alcnmydata'}
    }
    blackboard.dispatch_msg(:website_initialized)
    assert_equal(cache[:item_tracker_data], @tracker.instance_variable_get(:@cached))

    # Item should not be changed because of cache data
    refute(@tracker.send(:item_changed?, @tracker.send(:unique_id, :sample, 'mydata')))

    # Test the final writing of the cache data
    blackboard.dispatch_msg(:website_generated)
    expected = {
      :node_dependencies => {'alcn' => ['data'], '/alcn' => Set.new([[:sample, 'mydata']])},
      :item_data => {[:sample, 'mydata'] => 'alcnmydata'}
    }
    assert_equal(expected, cache[:item_tracker_data])

    website.verify
    node.verify
  end

end
