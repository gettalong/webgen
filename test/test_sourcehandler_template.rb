# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/tree'
require 'webgen/node'
require 'webgen/path'
require 'webgen/sourcehandler'
require 'stringio'

class TestSourceHandlerTemplate < Test::Unit::TestCase

  include Test::WebsiteHelper

  def setup
    super
    @obj = Webgen::SourceHandler::Template.new
  end

  def test_create_node
    root = Webgen::Node.new(Webgen::Tree.new.dummy_root, 'test/', 'test', {'lang' => 'de', :test => :value})
    node = @obj.create_node(root, path_with_meta_info('/default.template') {StringIO.new('')})

    assert_not_nil(node)
    assert_not_nil(node.node_info[:page])
    assert_equal('test/default.template', node.path)
  end

  def test_templates_for_node
    root = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/', {:test => :value})
    default_template = Webgen::Node.new(root, '/default.template', 'default.template')
    default_de_template = Webgen::Node.new(root, '/default.de.template', 'default.template', {'lang' => 'de'})
    other_template = Webgen::Node.new(root, '/other.template', 'other.template')
    stopped_template = Webgen::Node.new(root, '/stopped.html', 'stopped.page', { 'template' => nil})
    invalid_template = Webgen::Node.new(root, '/invalid.template', 'invalid.template', {'template' => 'invalidity'})
    chained_template = Webgen::Node.new(root, '/chained.template', 'chained.template', {'template' => 'other.template'})
    german_file = Webgen::Node.new(root, '/german.html', 'german.page', {'lang' => 'de', 'template' => 'other.template'})
    dir = Webgen::Node.new(root, '/dir/', 'dir')
    dir_default_template = Webgen::Node.new(dir, '/dir/default.template', 'default.template')

    assert_equal([], @obj.templates_for_node(default_template))
    assert_equal([], @obj.templates_for_node(stopped_template))
    assert_equal([default_template], @obj.templates_for_node(other_template))
    assert_equal([default_template], @obj.templates_for_node(invalid_template))
    assert_equal([default_template, other_template], @obj.templates_for_node(chained_template))
    assert_equal([default_de_template, other_template], @obj.templates_for_node(german_file))
    assert_equal([default_template], @obj.templates_for_node(dir_default_template))

    @website.cache.reset_volatile_cache
    root.tree.delete_node(default_template)
    assert_equal([], @obj.templates_for_node(other_template))
  end

  def test_default_template
    root = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/', {:test => :value})
    dir = Webgen::Node.new(root, '/dir/', 'dir/')
    template = Webgen::Node.new(root, '/default.template', 'default.template')

    assert_equal(template, @obj.default_template(root, nil))
    assert_equal(template, @obj.default_template(dir, nil))
    root.tree.delete_node(template)
    assert_nil(@obj.default_template(root, nil))
  end

end
