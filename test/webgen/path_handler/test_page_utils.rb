# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/path_handler/page_utils'
require 'webgen/content_processor'
require 'webgen/path'

class TestPageUtils < MiniTest::Unit::TestCase

  include Webgen::TestHelper

  class MyHandler
    include Webgen::PathHandler::PageUtils
  end

  def setup
    @handler = MyHandler.new
  end

  def test_parse_as_page!
    path = Webgen::Path.new('/test.html') { StringIO.new("---\nkey: value\n---\ncontent") }
    blocks = @handler.send(:parse_as_page!, path)
    assert_kind_of(Hash, blocks)
    assert_equal('content', blocks['content'])
    assert_equal('value', path.meta_info['key'])
  end

  def test_template_chain
    setup_website('path_handler.default_template' => 'default.template')
    @website.cache = Webgen::Cache.new
    @root = Webgen::Node.new(@website.tree.dummy_root, '/', '/')

    default_template = MyHandler::Node.new(@root, 'default.template', '/default.template')
    default_de_template = MyHandler::Node.new(@root, 'default.template', '/default.de.template', {'lang' => 'de'})
    other_template = MyHandler::Node.new(@root, 'other.template', '/other.template')
    stopped_template = MyHandler::Node.new(@root, 'stopped.html', '/stopped.page', { 'template' => nil})
    invalid_template = MyHandler::Node.new(@root, 'invalid.template', '/invalid.template', {'template' => 'invalidity'})
    chained_template = MyHandler::Node.new(@root, 'chained.template', '/chained.template', {'template' => 'other.template'})
    german_file = MyHandler::Node.new(@root, 'german.page', '/german.html', {'lang' => 'de', 'template' => 'other.template'})
    dir = Webgen::Node.new(@root, 'dir/', '/dir/')
    dir_default_template = MyHandler::Node.new(dir, 'default.template', '/dir/default.template')
    dir_dir = Webgen::Node.new(dir, 'dir/', '/dir/dir/')
    dir_dir_file = MyHandler::Node.new(dir_dir, 'file.page', '/dir/dir/file.html', {'lang' => 'en'})

    assert_equal([], default_template.template_chain)
    assert_equal([], stopped_template.template_chain)
    assert_equal([default_template], other_template.template_chain)
    assert_equal([default_template], invalid_template.template_chain)
    assert_equal([default_template, other_template], chained_template.template_chain)
    assert_equal([default_de_template, other_template], german_file.template_chain)
    assert_equal([default_template], dir_default_template.template_chain)
    assert_equal([default_template, dir_default_template], dir_dir_file.template_chain)

    @website.cache.reset_volatile_cache
    @root.tree.delete_node(default_template)
    assert_equal([], other_template.template_chain)
  end

  def test_render_block
    setup_context
    @website.ext.content_processor = Webgen::ContentProcessor.new
    node = MyHandler::Node.new(@website.tree.dummy_root, '/', '/')
    node.node_info[:blocks] = {'content' => 'mycontent'}

    # invalid block name
    assert_raises(Webgen::RenderError) { node.render_block('unknown', @context) }

    # nothing to render because pipeline is empty
    node.render_block('content', @context)
    assert_equal('mycontent', @context.content)

    # invalid content processor
    assert_raises(Webgen::Error) { node.render_block('content', @context, ['test']) }

    node.meta_info['blocks'] = {'content' => {'pipeline' => ['test']}}
    assert_raises(Webgen::Error) { node.render_block('content', @context) }

    # with content processor
    @website.ext.content_processor.register('test') {|ctx| ctx.content = 'test' + ctx.content; ctx}
    node.render_block('content', @context)
    assert_equal('testmycontent', @context.content)

    node.render_block('content', @context, ['test', 'test'])
    assert_equal('testtestmycontent', @context.content)
  end

end
