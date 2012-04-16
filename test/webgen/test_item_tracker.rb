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

  def node_referenced?(iid, node_alcn)
    iid == 'data'
  end

end

class TestItemTracker < MiniTest::Unit::TestCase

  def test_functionality
    # Needed mock objects
    website = MiniTest::Mock.new
    website.expect(:blackboard, blackboard = Webgen::Blackboard.new)
    website.expect(:cache, cache = {})
    node = MiniTest::Mock.new
    node.expect(:alcn, '/alcn')
    node.expect(:!, false)
    website.expect(:tree, {'/alcn' => node})

    tracker = Webgen::ItemTracker.new(website)
    tracker.register('Sample')
    tracker.add(node, :sample, 'mydata')

    # Node should be changed because no cache data is available
    assert(tracker.node_changed?(node))

    # Node should still be changed after it gets written
    blackboard.dispatch_msg(:after_node_written, node)
    assert(tracker.node_changed?(node))

    # Node should not be changed after all nodes are written
    blackboard.dispatch_msg(:after_all_nodes_written, node)
    refute(tracker.node_changed?(node))

    # Test the initial loading of the cache data
    cache[:item_tracker_data] = {
      :node_dependencies => {'/alcn' => [[:sample, 'mydata']], 'alcn' => ['data']},
      :item_data => {[:sample, 'mydata'] => 'alcnmydata', [:sample, 'other'] => 'alcnother'}
    }
    blackboard.dispatch_msg(:website_initialized)
    assert_equal(cache[:item_tracker_data], tracker.instance_variable_get(:@cached))

    # Node should not be changed because of cache data
    refute(tracker.node_changed?(node))

    # Test the final writing of the cache data
    blackboard.dispatch_msg(:after_node_written, node)      # needs to be done again because
    blackboard.dispatch_msg(:after_all_nodes_written, node) # of :website_initialized above
    blackboard.dispatch_msg(:website_generated)
    expected = {
      :node_dependencies => {'/alcn' => Set.new([[:sample, 'mydata']])},
      :item_data => {[:sample, 'mydata'] => 'alcnmydata'}
    }
    assert_equal(expected, cache[:item_tracker_data])

    refute(tracker.node_referenced?(node))

    website.verify
    node.verify
  end

end
