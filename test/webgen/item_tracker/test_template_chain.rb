# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'time'
require 'webgen/item_tracker/template_chain'

class TestItemTrackerTemplateChain < MiniTest::Unit::TestCase

  def setup
    @website = Object.new
    @node = node = Object.new
    @node.define_singleton_method(:alcn) { 'alcn' }
    @node.define_singleton_method(:template_chain) { [node] }
    @website.define_singleton_method(:tree) { {'alcn' => node} }
    @obj = Webgen::ItemTracker::TemplateChain.new(@website)
  end

  def test_item_id
    assert_equal('alcn', @obj.item_id(@node))
  end

  def test_item_data
    assert_equal(['alcn'], @obj.item_data('alcn'))
  end

  def test_item_changed?
    assert(@obj.item_changed?('unknown', 'old'))
    assert(@obj.item_changed?('alcn', ['old']))
    refute(@obj.item_changed?('alcn', ['alcn']))
  end

  def test_referenced_nodes
    assert_equal(['alcn'], @obj.referenced_nodes('alcn', 'data'))
  end

end
