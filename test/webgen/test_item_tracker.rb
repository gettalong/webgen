# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/item_tracker'
require 'webgen/blackboard'
require 'webgen/cache'
require 'webgen/node'

class Webgen::ItemTracker::Sample

  def initialize(website) #:nodoc:
    @website = website
  end

  def item_id(data) #:nodoc:
    data
  end

  def item_data(data) #:nodoc:
    if TestItemTracker::Data.has_key?(data)
      'alcn' + TestItemTracker::Data[data].to_s
    else
      raise "Unkown key"
    end
  end

  def item_changed?(iid, old_data) #:nodoc:
    'alcn' + TestItemTracker::Data[iid].to_s != old_data
  end

  def referenced_nodes(iid, _)
    [iid]
  end

end

class TestItemTracker < Minitest::Test

  DummyNode = Struct.new(:alcn, :node_info)

  Data = {'/alcn' => 'mydata'}

  def test_functionality
    # Needed stub objects
    website = Struct.new(:blackboard, :cache, :tree).new
    website.blackboard = blackboard = Webgen::Blackboard.new
    website.cache = cache = Webgen::Cache.new

    node = DummyNode.new('/alcn', {})
    other = DummyNode.new('/other', {})
    website.tree = {'/alcn' => node, '/other' => other}

    tracker = Webgen::ItemTracker.new(website)
    tracker.register('Sample')
    tracker.add(node, :sample, '/alcn')

    website.blackboard.add_listener(:after_all_nodes_written) {cache.reset_volatile_cache}

    # Node should be changed because no cache data is available
    assert(tracker.node_changed?(node))

    # Node should still be changed after it gets written
    blackboard.dispatch_msg(:after_node_written, node)
    assert(tracker.node_changed?(node))

    Data['/alcn'] = 'other'

    # Node should still be changed after all nodes are written because Data changed
    blackboard.dispatch_msg(:after_all_nodes_written)
    blackboard.dispatch_msg(:before_all_nodes_written)
    assert(tracker.node_changed?(node))

    # Node should not be changed anymore
    blackboard.dispatch_msg(:after_node_written, node)
    blackboard.dispatch_msg(:after_all_nodes_written)
    blackboard.dispatch_msg(:before_all_nodes_written)
    refute(tracker.node_changed?(node))

    # Node should be changed because item id got invalid
    blackboard.dispatch_msg(:after_node_written, node)
    blackboard.dispatch_msg(:after_all_nodes_written)
    Data.delete('/alcn')
    blackboard.dispatch_msg(:before_all_nodes_written)
    assert(tracker.node_changed?(node))

    # Node should not be changed anymore, again
    blackboard.dispatch_msg(:after_node_written, node)
    blackboard.dispatch_msg(:after_all_nodes_written)
    blackboard.dispatch_msg(:before_all_nodes_written)
    refute(tracker.node_changed?(node))

    # Re-add needed item and data
    Data['/alcn'] = 'other'
    tracker.add(node, :sample, '/alcn')

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
  end

end
