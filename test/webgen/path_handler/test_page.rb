# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/path_handler/page'
require 'webgen/path'

class TestPathHandlerPage < MiniTest::Unit::TestCase

  include Webgen::TestHelper

  def setup
    setup_website('website.lang' => 'en')
    @root = Webgen::Node.new(@website.tree.dummy_root, '/', '/')
    @page = Webgen::PathHandler::Page.new(@website)
  end

  def test_create_node
    path = Webgen::Path.new('/default.page', 'dest_path' => '<parent><basename><ext>') { StringIO.new('test') }
    node = @page.create_nodes(path, ['content'])
    refute_nil(node)
    assert_equal(['content'], node.blocks)
    assert_equal('/default.en.html', node.alcn)
  end

end
