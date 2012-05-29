# -*- encoding: utf-8 -*-

require 'helper'
require 'ostruct'
require 'stringio'
require 'logger'
require 'webgen/path_handler/copy'
require 'webgen/content_processor'
require 'webgen/tree'
require 'webgen/node'
require 'webgen/path'

class TestPathHandlerCopy < MiniTest::Unit::TestCase

  def setup
    @website = MiniTest::Mock.new
    @website.expect(:tree, Webgen::Tree.new(@website))
    @website.expect(:ext, OpenStruct.new)
    @website.expect(:config, {})
    @website.expect(:logger, Logger.new(StringIO.new))

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
    node = @copy.create_nodes(Webgen::Path.new('/default.css', 'dest_path' => '<parent><basename><ext>'))
    refute_nil(node)
    assert_nil(node.meta_info['pipeline'])
    assert_equal('/default.css', node.dest_path)

    node = @copy.create_nodes(Webgen::Path.new('/other.test.css', 'dest_path' => '<parent><basename><ext>'))
    refute_nil(node)
    assert_equal(['test'], node.meta_info['pipeline'])
    assert_equal('/other.css', node.dest_path)

    node = @copy.create_nodes(Webgen::Path.new('/other.unknown.css', 'dest_path' => '<parent><basename><ext>'))
    assert_nil(node.meta_info['pipeline'])
    assert_equal('/other.unknown.css', node.dest_path)

    node = @copy.create_nodes(Webgen::Path.new('/first.test.test.unknown.css', 'dest_path' => '<parent><basename><ext>'))
    assert_equal(['test', 'test'], node.meta_info['pipeline'])
    assert_equal('/first.unknown.css', node.dest_path)

    node = @copy.create_nodes(Webgen::Path.new('/first.test.test.unknown.ha', 'dest_path' => '<parent><basename><ext>'))
    assert_equal(['test', 'test', :ha], node.meta_info['pipeline'])
    assert_equal('/first.unknown.llo', node.dest_path)

    node = @copy.create_nodes(Webgen::Path.new('/first.ha', 'dest_path' => '<parent><basename><ext>'))
    assert_equal([:ha], node.meta_info['pipeline'])
    assert_equal('/first.llo', node.dest_path)

    node = @copy.create_nodes(Webgen::Path.new('/other.test.css', 'dest_path' => '<parent><basename><ext>', 'pipeline' => ['testing']))
    assert_equal(['testing'], node.meta_info['pipeline'])
    assert_equal('/other.test.css', node.dest_path)

    node = @copy.create_nodes(Webgen::Path.new('/other.unke.css', 'dest_path' => '<parent><basename><ext>', 'pipeline' => ['test']))
    assert_equal(['test'], node.meta_info['pipeline'])

    node = @copy.create_nodes(Webgen::Path.new('/other', 'dest_path' => '<parent><basename><ext>'))
    assert_nil(node.meta_info['pipeline'])
    assert_equal('/other', node.dest_path)

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
