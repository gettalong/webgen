# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/path_handler/copy'
require 'webgen/content_processor'
require 'webgen/path'

class TestPathHandlerCopy < MiniTest::Unit::TestCase

  include Webgen::TestHelper

  def setup
    setup_website
    @website.ext.content_processor = Webgen::ContentProcessor.new
    @website.ext.content_processor.register('test') do |context|
      context.content = context.content.reverse
    end
    @website.ext.content_processor.register('ha', :ext_map => {'ha' => 'llo'}) do |context|
      context.content = context.content.reverse
    end

    @copy = Webgen::PathHandler::Copy.new(@website)
    @root = Webgen::Node.new(@website.tree.dummy_root, '/', '/')
  end

  def test_create_node
    check_node = lambda do |src_path, mi, dest_path, pipeline|
      node = @copy.create_nodes(Webgen::Path.new(src_path, {'dest_path' => '<parent><basename><ext>'}.merge(mi)))
      refute_nil(node)
      assert_equal(pipeline, node.meta_info['pipeline'])
      assert_equal(dest_path, node.dest_path)
    end

    check_node.call('/default.css', {}, '/default.css', nil)
    check_node.call('/other.test.css', {}, '/other.css', ['test'])
    check_node.call('/other.unknown.css', {}, '/other.unknown.css', nil)
    check_node.call('/first.test.test.unknown.css', {}, '/first.unknown.css', ['test', 'test'])
    check_node.call('/first.test.test.unknown.ha', {}, '/first.unknown.llo', ['test', 'test', :ha])
    check_node.call('/first.ha', {}, '/first.llo', [:ha])
    check_node.call('/other.test.css', {'pipeline' => ['testing']}, '/other.test.css', ['testing'])
    check_node.call('/other.unke.css', {'pipeline' => ['test']}, '/other.unke.css', ['test'])
    check_node.call('/other', {}, '/other', nil)

    assert_raises(Webgen::NodeCreationError) do
      @copy.create_nodes(Webgen::Path.new('/other.test.css', 'dest_path' => '<parent><basename><ext>'))
    end
  end

  def test_content
    path = Webgen::Path.new('/default.css', 'dest_path' => '<parent><basename><ext>') {StringIO.new('# header')}
    node = @copy.create_nodes(path)
    assert_kind_of(Webgen::Path, @copy.content(node))
    assert_equal('# header', @copy.content(node).data)

    path = Webgen::Path.new('/other.test.css', 'dest_path' => '<parent><basename><ext>') {StringIO.new('# other')}
    node = @copy.create_nodes(path)
    assert_equal('# other'.reverse, @copy.content(node))
  end

end
