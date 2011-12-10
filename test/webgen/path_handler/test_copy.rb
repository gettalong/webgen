# -*- encoding: utf-8 -*-

require 'helper'
require 'ostruct'
require 'stringio'
require 'webgen/path_handler/copy'
require 'webgen/content_processor'
require 'webgen/tree'
require 'webgen/node'
require 'webgen/path'

class TestPathHandlerCopy < MiniTest::Unit::TestCase

  class TestCP
    def call(context); context.content = context.content.reverse; end
  end

  def setup
    @website = MiniTest::Mock.new
    @website.expect(:tree, Webgen::Tree.new(@website))
    @website.expect(:ext, OpenStruct.new)
    @website.ext.content_processor = Webgen::ContentProcessor.new
    @website.ext.content_processor.register('test') do |context|
      context.content = context.content.reverse
    end

    @copy = Webgen::PathHandler::Copy.new(@website)
    @root = Webgen::Node.new(@website.tree.dummy_root, '/', '/')

    # @without = @obj.create_node(path_with_meta_info('/default.css') {StringIO.new('# header')})
    # @with = @obj.create_node(path_with_meta_info('/other.test.css') {StringIO.new('# header')})
  end

  def test_create_node
    node = @copy.create_nodes(Webgen::Path.new('/default.css', 'dest_path' => ':parent:basename:ext'))
    refute_nil(node)
    assert_nil(node.meta_info['pipeline'])
    assert_equal('/default.css', node.dest_path)

    node = @copy.create_nodes(Webgen::Path.new('/other.test.css', 'dest_path' => ':parent:basename:ext'))
    refute_nil(node)
    assert_equal(['test'], node.meta_info['pipeline'])
    assert_equal('/other.css', node.dest_path)

    node = @copy.create_nodes(Webgen::Path.new('/other.unke.css', 'dest_path' => ':parent:basename:ext', 'pipeline' => ['test']))
    assert_equal(['test'], node.meta_info['pipeline'])

    node = @copy.create_nodes(Webgen::Path.new('/other.unknown.css', 'dest_path' => ':parent:basename:ext'))
    assert_nil(node.meta_info['pipeline'])

    assert_raises(Webgen::NodeCreationError) do
      @copy.create_nodes(Webgen::Path.new('/other.test.css', 'dest_path' => ':parent:basename:ext', 'pipeline' => ['unke']))
    end
  end

  def test_content
    @website.ext.source = MiniTest::Mock.new
    @website.ext.source.expect(:paths, {'/default.css' => Webgen::Path.new('/default.css') {StringIO.new('# header')},
                                 '/other.test.css' => Webgen::Path.new('/other.test.css') {StringIO.new('# other')}})

    node = @copy.create_nodes(Webgen::Path.new('/default.css', 'dest_path' => ':parent:basename:ext'))
    assert_kind_of(Webgen::Path, @copy.content(node))
    assert_equal('# header', @copy.content(node).data)

    node = @copy.create_nodes(Webgen::Path.new('/other.test.css', 'dest_path' => ':parent:basename:ext'))
    assert_equal('# other'.reverse, @copy.content(node))
  end

end
