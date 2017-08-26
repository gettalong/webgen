# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/path_handler/template'
require 'webgen/path'
require 'webgen/cache'

class TestPathHandlerTemplate < Minitest::Test

  include Webgen::TestHelper

  def test_create_nodes
    setup_website
    Webgen::Node.new(@website.tree.dummy_root, '/', '/')
    @template = Webgen::PathHandler::Template.new(@website)

    path = Webgen::Path.new('/default.template', 'dest_path' => '<parent><basename><ext>') { StringIO.new('test') }
    node = @template.create_nodes(path, ['content'])
    refute_nil(node)
    assert_equal(['content'], node.blocks)
    assert(node['no_output'])
  end

end
