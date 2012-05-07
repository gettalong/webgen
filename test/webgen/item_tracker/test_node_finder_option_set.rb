# -*- encoding: utf-8 -*-

require 'helper'
require 'webgen/tree'
require 'webgen/node_finder'
require 'webgen/item_tracker/node_finder_option_set'

class TestNodeFinderOptionSet < MiniTest::Unit::TestCase

  def setup
    @website = MiniTest::Mock.new
    @website.expect(:config, {'node_finder.option_sets' => {}})
    @website.expect(:tree, Webgen::Tree.new(@website))
    @website.expect(:node_finder, Webgen::NodeFinder.new(@website))
    @obj = Webgen::ItemTracker::NodeFinderOptionSet.new(@website)
  end

  def test_item_id
    @node = MiniTest::Mock.new
    @node.expect(:alcn, 'node')
    assert_equal([{:some => 'option', :is => 'here'}, 'node', :content], @obj.item_id({:some => 'option', :is => 'here'}, @node, :content))
  end

  def test_item_data
    nodes = Test.create_default_nodes(@website.tree)
    assert_equal([["/somename.en.html", [["/somename.en.html#othertest", ["/somename.en.html#nestedpath"]]]],
                  ["/somename.de.html", ["/somename.de.html#othertest"]]],
                 @obj.item_data({:alcn => '/some*'}, '/', :content))
  end

  def test_changed?
    nodes = Test.create_default_nodes(@website.tree)
    item_tracker = MiniTest::Mock.new
    item_tracker.expect(:item_changed?, false, [:node_meta_info, nil])
    @website.expect(:item_tracker, item_tracker)

    old_data = @obj.item_data({:alcn => '/some*'}, '/', :meta_info)
    assert(@obj.changed?([{:alcn => '/some*'}, '/', :meta_info], []))
    refute(@obj.changed?([{:alcn => '/some*'}, '/', :meta_info], old_data))
  end

  def test_node_referenced?
    nodes = Test.create_default_nodes(@website.tree)
    assert(@obj.node_referenced?([{:alcn => '/some*'}, '/', :content], '/somename.en.html'))
    refute(@obj.node_referenced?([{:alcn => '/some*'}, '/', :content], '/other.en.html'))
  end

end
