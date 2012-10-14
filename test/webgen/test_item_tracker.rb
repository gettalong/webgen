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
    'alcn' + TestItemTracker::Data[data].to_s
  end

  def changed?(iid, old_data) #:nodoc:
    'alcn' + TestItemTracker::Data[iid].to_s != old_data
  end

  def node_referenced?(iid, _, node_alcn)
    iid == node_alcn
  end

end

class TestItemTracker < MiniTest::Unit::TestCase

  Data = {'/alcn' => 'mydata'}

  def test_functionality
    # Needed mock objects
    website = MiniTest::Mock.new
    website.expect(:blackboard, blackboard = Webgen::Blackboard.new)
    website.expect(:cache, cache = {})
    node = MiniTest::Mock.new
    node.expect(:alcn, '/alcn')
    node.expect(:!, false)
    node.expect(:hash, 12345)
    other = MiniTest::Mock.new
    other.expect(:alcn, '/other')
    other.expect(:!, false)
    other.expect(:hash, 12346)
    website.expect(:tree, {'/alcn' => node, '/other' => other})

    tracker = Webgen::ItemTracker.new(website)
    tracker.register('Sample')
    tracker.add(node, :sample, '/alcn')

    # Node should be changed because no cache data is available
    assert(tracker.node_changed?(node))

    # Node should still be changed after it gets written
    blackboard.dispatch_msg(:after_node_written, node)
    assert(tracker.node_changed?(node))

    Data['/alcn'] = 'other'

    # Node should still be changed after all nodes are written because Data changed
    blackboard.dispatch_msg(:after_all_nodes_written)
    assert(tracker.node_changed?(node))

    # Node should not be changed anymore
    blackboard.dispatch_msg(:after_node_written, node)
    blackboard.dispatch_msg(:after_all_nodes_written)
    refute(tracker.node_changed?(node))

    # Test the initial loading of the cache data
    cache[:item_tracker_data] = {
      :node_dependencies => {'/alcn' => [[:sample, '/alcn']], 'alcn' => ['data']},
      :item_data => {[:sample, '/alcn'] => 'alcnother', [:sample, 'other'] => 'alcnother'}
    }
    blackboard.dispatch_msg(:website_initialized)
    assert_equal(cache[:item_tracker_data], tracker.instance_variable_get(:@cached))

    # Node should not be changed because of cache data
    refute(tracker.node_changed?(node))

    # Test the final writing of the cache data
    blackboard.dispatch_msg(:after_node_written, node)      # needs to be done again because
    blackboard.dispatch_msg(:after_all_nodes_written) # of :website_initialized above
    blackboard.dispatch_msg(:website_generated)
    expected = {
      :node_dependencies => {'/alcn' => Set.new([[:sample, '/alcn']])},
      :item_data => {[:sample, '/alcn'] => 'alcnother'}
    }
    assert_equal(expected, cache[:item_tracker_data])

    # Test whether the node is referenced
    tracker.add(other, :sample, '/alcn')
    blackboard.dispatch_msg(:after_node_written, other)
    blackboard.dispatch_msg(:after_all_nodes_written)

    assert(tracker.node_referenced?(node))

    website.verify
    node.verify
  end

end
