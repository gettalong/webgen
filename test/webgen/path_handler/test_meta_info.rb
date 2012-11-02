# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/path_handler/meta_info'
require 'webgen/path'

class TestPathHandlerMetaInfo < MiniTest::Unit::TestCase

  include Webgen::TestHelper

  class TestPathHandler
    include Webgen::PathHandler::Base
    public :create_node
  end

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
    setup_website
    @root = Webgen::Node.new(@website.tree.dummy_root, '/', '/')
    @mi = Webgen::PathHandler::MetaInfo.new(@website)
    @ph = TestPathHandler.new(@website)
  end

  def setup_default_node
    @path = Webgen::Path.new('/metainfo', 'dest_path' => '<parent><basename><ext>')
    @mi.create_nodes(@path, Webgen::Page.from_data(CONTENT).blocks)
  end

  def test_create_node
    setup_default_node
    result = [['/default.*', {'title' => 'new title', 'before' => 'valbef'}],
              ['/*/', {'title' => 'test'}]]
    @mi.instance_variable_get(:@paths).each_with_index do |(pattern, mi), index|
      assert_equal(result[index].first, pattern)
      assert_equal(result[index].last, Marshal.load(mi))
    end

    result = [['/default.css', {'after' => 'valaft'}],
              ['/other.page', {'title' => 'Not Other'}]]
    @mi.instance_variable_get(:@alcns).each_with_index do |(pattern, mi), index|
      assert_equal(result[index].first, pattern)
      assert_equal(result[index].last, Marshal.load(mi))
    end

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
    node = @ph.create_node(path)

    setup_default_node

    assert('valaft', node['after'])
  end

  def test_after_node_created
    setup_default_node

    path = Webgen::Path.new('/default.css', 'dest_path' => '<parent><basename><ext>')
    node = @ph.create_node(path)

    refute_equal('valaft', node['after'])
    @website.blackboard.dispatch_msg(:after_node_created, node)
    assert_equal('valaft', node['after'])
  end

end
