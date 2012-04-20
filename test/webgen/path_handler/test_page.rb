# -*- encoding: utf-8 -*-

require 'helper'
require 'ostruct'
require 'stringio'
require 'webgen/path_handler/page'
require 'webgen/tree'
require 'webgen/node'
require 'webgen/path'

class TestPathHandlerPage < MiniTest::Unit::TestCase

  def setup
    @website = MiniTest::Mock.new
    @website.expect(:tree, Webgen::Tree.new(@website))
    @website.expect(:config, {'website.lang' => 'en'})
    @root = Webgen::Node.new(@website.tree.dummy_root, '/', '/')
    @page = Webgen::PathHandler::Page.new(@website)
  end

  def test_create_node
    path = Webgen::Path.new('/default.page', 'dest_path' => ':parent:basename:ext') { StringIO.new('test') }
    node = @page.create_nodes(path, ['content'])
    refute_nil(node)
    assert_equal(['content'], @page.blocks(node))
    assert_equal('/default.en.html', node.alcn)
  end

end
