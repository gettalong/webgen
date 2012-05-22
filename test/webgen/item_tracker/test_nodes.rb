# -*- encoding: utf-8 -*-

require 'helper'
require 'ostruct'
require 'webgen/tree'
require 'webgen/node_finder'
require 'webgen/item_tracker/nodes'

class TestItemTrackerNodes < MiniTest::Unit::TestCase

  def self.node_list(website, options)
    website.tree.root.children
  end

  def setup
    @website = MiniTest::Mock.new
    @website.expect(:config, {'node_finder.option_sets' => {}})
    @website.expect(:tree, Webgen::Tree.new(@website))
    @website.expect(:ext, OpenStruct.new)
    @website.ext.node_finder =  Webgen::NodeFinder.new(@website)
    @obj = Webgen::ItemTracker::Nodes.new(@website)
    @args1 = [['TestItemTrackerNodes', 'node_list'], {}, :meta_info]
    @args2 = [:node_finder_option_set, {:opts => {:alcn => '/some*'}, :ref_alcn => '/'}, :meta_info]
  end

  def test_item_id
    assert_equal(@args1, @obj.item_id(*@args1))
    assert_equal(@args2, @obj.item_id(*@args2))
  end

  def test_item_data
    nodes = Test.create_default_nodes(@website.tree)

    assert_equal(["/somename.en.html", "/somename.de.html", "/other.html", "/other.en.html", "/dir/", "/dir2/"],
                 @obj.item_data(*@args1))

    assert_equal([["/somename.en.html", [["/somename.en.html#othertest", ["/somename.en.html#nestedpath"]]]],
                  ["/somename.de.html", ["/somename.de.html#othertest"]]],
                 @obj.item_data(*@args2))
  end

  def test_changed?
    nodes = Test.create_default_nodes(@website.tree)
    @website.ext.item_tracker = MiniTest::Mock.new
    @website.ext.item_tracker.expect(:item_changed?, false, [:node_meta_info, nil])

    [@args1, @args2].each do |args|
      old_data = @obj.item_data(*args)
      assert(@obj.changed?(args, []))
      refute(@obj.changed?(args, old_data))
    end
  end

  def test_node_referenced?
    nodes = Test.create_default_nodes(@website.tree)

    assert(@obj.node_referenced?(@args1, '/somename.en.html'))
    refute(@obj.node_referenced?(@args1, '/dir/file.html'))

    assert(@obj.node_referenced?(@args2, '/somename.en.html'))
    refute(@obj.node_referenced?(@args2, '/other.en.html'))
  end

end
