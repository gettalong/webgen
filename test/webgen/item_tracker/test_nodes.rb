# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/item_tracker/nodes'
require 'webgen/node_finder'

class TestItemTrackerNodes < Minitest::Test

  include Webgen::TestHelper

  def self.node_list(website, options)
    website.tree.root.children.select {|c| c.alcn =~ /^\/file/}
  end

  def setup
    setup_website('node_finder.option_sets' => {})
    @website.ext.node_finder =  Webgen::NodeFinder.new(@website)
    @obj = Webgen::ItemTracker::Nodes.new(@website)
    @args1 = [['TestItemTrackerNodes', 'node_list'], {}, :meta_info]
    @args2 = [:node_finder_option_set, {:opts => {:alcn => ['/file.de*', '/file.*.html']}, :ref_alcn => '/'}, :meta_info]
  end

  def test_item_id
    assert_equal(@args1, @obj.item_id(*@args1))
    assert_equal(@args2, @obj.item_id(*@args2))
  end

  def test_item_data
    setup_default_nodes(@website.tree)

    assert_equal(["/file.en.html", "/file.de.html"],
                 @obj.item_data(*@args1))

    assert_equal(["/file.en.html", "/file.de.html"],
                 @obj.item_data(*@args2))
  end

  def test_item_changed?
    setup_default_nodes(@website.tree)
    @website.ext.item_tracker = MiniTest::Mock.new
    2.times do
      @website.ext.item_tracker.expect(:item_changed?, false, [:node_meta_info, @website.tree['/file.en.html']])
      @website.ext.item_tracker.expect(:item_changed?, false, [:node_meta_info, @website.tree['/file.de.html']])
    end

    [@args1, @args2].each do |args|
      old_data = @obj.item_data(*args)
      assert(@obj.item_changed?(args, []))
      refute(@obj.item_changed?(args, old_data))
    end

    @website.ext.item_tracker.verify
  end

  def test_referenced_nodes
    setup_default_nodes(@website.tree)

    assert(["/file.en.html", "/file.de.html", "/other.html", "/other.en.html", "/german.de.html",
            "/dir/", "/dir2/"].map {|f| @website.tree[f]},
           @obj.referenced_nodes(@args1, @obj.item_data(*@args1)))
  end

end
