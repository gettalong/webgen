# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/item_tracker/nodes'
require 'webgen/node_finder'

class TestItemTrackerNodes < MiniTest::Unit::TestCase

  include Webgen::TestHelper

  def self.node_list(website, options)
    website.tree.root.children
  end

  def setup
    setup_website('node_finder.option_sets' => {})
    @website.ext.node_finder =  Webgen::NodeFinder.new(@website)
    @obj = Webgen::ItemTracker::Nodes.new(@website)
    @args1 = [['TestItemTrackerNodes', 'node_list'], {}, :meta_info]
    @args2 = [:node_finder_option_set, {:opts => {:alcn => '/file*'}, :ref_alcn => '/'}, :meta_info]
  end

  def test_item_id
    assert_equal(@args1, @obj.item_id(*@args1))
    assert_equal(@args2, @obj.item_id(*@args2))
  end

  def test_item_data
    setup_default_nodes(@website.tree)

    assert_equal(["/file.en.html", "/file.de.html", "/other.html", "/other.en.html", "/german.de.html", "/dir/", "/dir2/"],
                 @obj.item_data(*@args1))

    assert_equal([["/file.en.html", [["/file.en.html#frag", ["/file.en.html#nested"]]]],
                  ["/file.de.html", ["/file.de.html#frag"]]],
                 @obj.item_data(*@args2))
  end

  def test_item_changed?
    setup_default_nodes(@website.tree)
    @website.ext.item_tracker = MiniTest::Mock.new
    @website.ext.item_tracker.expect(:item_changed?, false, [:node_meta_info, nil])

    [@args1, @args2].each do |args|
      old_data = @obj.item_data(*args)
      assert(@obj.item_changed?(args, []))
      refute(@obj.item_changed?(args, old_data))
    end
  end

  def test_referenced_nodes
    setup_default_nodes(@website.tree)

    assert(["/file.en.html", "/file.de.html", "/other.html", "/other.en.html", "/german.de.html",
            "/dir/", "/dir2/"].map {|f| @website.tree[f]},
           @obj.referenced_nodes(@args1, @obj.item_data(*@args1)))
  end

end
