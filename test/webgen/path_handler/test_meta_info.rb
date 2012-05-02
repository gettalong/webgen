# -*- encoding: utf-8 -*-

require 'helper'
require 'stringio'
require 'logger'
require 'webgen/path_handler/meta_info'
require 'webgen/blackboard'
require 'webgen/tree'
require 'webgen/node'
require 'webgen/path'

class TestPathHandlerMetaInfo < MiniTest::Unit::TestCase

  CONTENT=<<EOF
--- paths
/default.*:
  title: new title
  before: valbef

/*/:
  title: test
--- alcn
/default.css:
  after: valaft

/other.page:
  title: Not Other
EOF

  def setup
    @website = MiniTest::Mock.new
    @website.expect(:tree, Webgen::Tree.new(@website))
    @website.expect(:config, {})
    @website.expect(:logger, Logger.new(StringIO.new))
    @website.expect(:blackboard, Webgen::Blackboard.new)
    @root = Webgen::Node.new(@website.tree.dummy_root, '/', '/')
    @mi = Webgen::PathHandler::MetaInfo.new(@website)
  end

  def setup_default_node
    @path = Webgen::Path.new('/metainfo', 'dest_path' => '<parent><basename><ext>')
    @node = @mi.create_nodes(@path, Webgen::Page.from_data(CONTENT).blocks)
  end

  def test_create_node
    setup_default_node
    refute_nil(@node)
    assert_equal({'/default.*' => {'title' => 'new title', 'before' => 'valbef'},
                 '/*/' => {'title' => 'test'}}, @node.node_info[:mi_paths])
    assert_equal({'/default.css' => {'after' => 'valaft'},
                 '/other.page' => {'title' => 'Not Other'}}, @node.node_info[:mi_alcn])

    path = Webgen::Path.new('/default.metainfo', 'dest_path' => '<parent><basename><ext>')
    assert_raises(Webgen::NodeCreationError) do
      @mi.create_nodes(path, Webgen::Page.from_data("--- alcn\nhallo: test\n\ntest]du").blocks)
    end
  end

  def test_before_node_created
    setup_default_node

    path = Webgen::Path.new('/default.css')
    @website.blackboard.dispatch_msg(:before_node_created, path)
    assert('valbef', path.meta_info['before'])

    path = Webgen::Path.new('/hallo/')
    @website.blackboard.dispatch_msg(:before_node_created, path)
    assert('test', path.meta_info['title'])
  end

  def test_update_existing_nodes
    path = Webgen::Path.new('/default.css', 'dest_path' => '<parent><basename><ext>')
    node = @mi.create_nodes(path, {})

    setup_default_node

    assert('valaft', node['after'])
  end

  def test_after_node_created
    setup_default_node

    path = Webgen::Path.new('/default.css', 'dest_path' => '<parent><basename><ext>')
    node = @mi.create_nodes(path, {})

    @website.expect(:ext, OpenStruct.new)
    @website.ext.item_tracker = MiniTest::Mock.new
    @website.ext.item_tracker.expect(:add, nil, [node, :node_meta_info, node.alcn])

    refute_equal('valaft', node['after'])
    @website.blackboard.dispatch_msg(:after_node_created, node)
    assert_equal('valaft', node['after'])
    @website.ext.item_tracker.verify
  end

end
