# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/item_tracker/missing_node'
require 'webgen/blackboard'

class TestItemTrackerMissingNode < MiniTest::Unit::TestCase

  class StubTree

    attr_accessor :answer

    def resolve_node(path, lang)
      @answer
    end

  end

  def setup
    @website = MiniTest::Mock.new
    @website.expect(:tree, StubTree.new)
    @website.expect(:blackboard, Webgen::Blackboard.new)
    @obj = Webgen::ItemTracker::MissingNode.new(@website)
  end

  def test_item_id
    assert_equal(['id', nil], @obj.item_id('id'))
    assert_equal(['id', 'lang'], @obj.item_id('id', 'lang'))
  end

  def test_item_data
    @website.tree.answer = nil
    assert_equal(true, @obj.item_data('id', 'lang'))
    @website.tree.answer = :a42
    assert_same(false, @obj.item_data('id', 'lang'))
  end

  def test_changed?
    @website.tree.answer = nil

    # run where missing node item was added
    assert(@obj.changed?(['alcn', 'lang'], true))

    @website.blackboard.dispatch_msg(:after_all_nodes_written)

    # run where at least one new node was created
    @website.blackboard.dispatch_msg(:after_node_created)
    assert(@obj.changed?(['alcn', 'lang'], true))

    @website.blackboard.dispatch_msg(:after_all_nodes_written)
    @website.blackboard.dispatch_msg(:after_all_nodes_written)

    # run where no new nodes were created and therefore "changing" stops
    refute(@obj.changed?(['alcn', 'lang'], true))

    @website.blackboard.dispatch_msg(:after_all_nodes_written)
    @website.blackboard.dispatch_msg(:website_generated)

    # on next invocation of website generation
    @website.tree.answer = :a42
    assert(@obj.changed?(['alcn', 'lang'], true))
    refute(@obj.changed?(['alcn', 'lang'], false))
  end

  def test_node_referenced?
    assert(@obj.node_referenced?(['alcn', 'lang'], true, 'alcn'))
    refute(@obj.node_referenced?(['other', 'lang'], true, 'alcn'))
  end

end
