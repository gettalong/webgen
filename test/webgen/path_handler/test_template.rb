# -*- encoding: utf-8 -*-

require 'helper'
require 'ostruct'
require 'stringio'
require 'logger'
require 'webgen/path_handler/template'
require 'webgen/tree'
require 'webgen/node'
require 'webgen/path'
require 'webgen/blackboard'
require 'webgen/cache'

class TestPathHandlerTemplate < MiniTest::Unit::TestCase

  def setup
    @website = MiniTest::Mock.new
    @website.expect(:config, {'path_handler.template.default_template' => 'default.template'})
    @website.expect(:tree, Webgen::Tree.new(@website))
    @website.expect(:logger, Logger.new(StringIO.new))
    @website.expect(:blackboard, Webgen::Blackboard.new)
    @website.expect(:cache, Webgen::Cache.new)

    @template = Webgen::PathHandler::Template.new(@website)
    @root = Webgen::Node.new(@website.tree.dummy_root, '/', '/')
  end

  def test_create_nodes
    path = Webgen::Path.new('/default.template', 'dest_path' => ':parent:basename:ext') { StringIO.new('test') }
    node = @template.create_nodes(path, ['content'])
    refute_nil(node)
    assert_equal(['content'], @template.blocks(node))
  end

  def test_template_chain
    default_template = Webgen::Node.new(@root, 'default.template', '/default.template')
    default_de_template = Webgen::Node.new(@root, 'default.template', '/default.de.template', {'lang' => 'de'})
    other_template = Webgen::Node.new(@root, 'other.template', '/other.template')
    stopped_template = Webgen::Node.new(@root, 'stopped.html', '/stopped.page', { 'template' => nil})
    invalid_template = Webgen::Node.new(@root, 'invalid.template', '/invalid.template', {'template' => 'invalidity'})
    chained_template = Webgen::Node.new(@root, 'chained.template', '/chained.template', {'template' => 'other.template'})
    german_file = Webgen::Node.new(@root, 'german.page', '/german.html', {'lang' => 'de', 'template' => 'other.template'})
    dir = Webgen::Node.new(@root, 'dir/', '/dir/')
    dir_default_template = Webgen::Node.new(dir, 'default.template', '/dir/default.template')
    dir_dir = Webgen::Node.new(dir, 'dir/', '/dir/dir/')
    dir_dir_file = Webgen::Node.new(dir_dir, 'file.page', '/dir/dir/file.html', {'lang' => 'en'})

    assert_equal([], @template.template_chain(default_template))
    assert_equal([], @template.template_chain(stopped_template))
    assert_equal([default_template], @template.template_chain(other_template))
    assert_equal([default_template], @template.template_chain(invalid_template))
    assert_equal([default_template, other_template], @template.template_chain(chained_template))
    assert_equal([default_de_template, other_template], @template.template_chain(german_file))
    assert_equal([default_template], @template.template_chain(dir_default_template))
    assert_equal([default_template, dir_default_template], @template.template_chain(dir_dir_file))

    @website.cache.reset_volatile_cache
    @root.tree.delete_node(default_template)
    assert_equal([], @template.template_chain(other_template))
  end

  def test_default_template
    dir = Webgen::Node.new(@root, 'dir/', '/dir/')
    template = Webgen::Node.new(@root, 'default.template', '/default.template')

    assert_equal(template, @template.default_template(@root, nil))
    assert_equal(template, @template.default_template(dir, nil))
    @website.tree.delete_node(template)
    assert_nil(@template.default_template(@root, nil))
  end

end
