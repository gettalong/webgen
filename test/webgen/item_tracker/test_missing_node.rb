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

  def test_item_changed?
    @website.tree.answer = nil

    # run where missing node item was added
    assert(@obj.item_changed?(['alcn', 'lang'], true))

    @website.blackboard.dispatch_msg(:after_all_nodes_written)

    # run where at least one new node was created
    @website.blackboard.dispatch_msg(:after_node_created)
    assert(@obj.item_changed?(['alcn', 'lang'], true))

    @website.blackboard.dispatch_msg(:after_all_nodes_written)
    @website.blackboard.dispatch_msg(:after_all_nodes_written)

    # run where no new nodes were created and therefore "changing" stops
    refute(@obj.item_changed?(['alcn', 'lang'], true))

    @website.blackboard.dispatch_msg(:after_all_nodes_written)
    @website.blackboard.dispatch_msg(:website_generated)

    # on next invocation of website generation
    @website.tree.answer = :a42
    assert(@obj.item_changed?(['alcn', 'lang'], true))
    refute(@obj.item_changed?(['alcn', 'lang'], false))
  end

  def test_referenced_nodes
    assert_equal(['alcn'], @obj.referenced_nodes(['alcn', 'lang'], true))
  end

end
