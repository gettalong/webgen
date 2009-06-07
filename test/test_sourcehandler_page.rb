# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/sourcehandler'
require 'stringio'

class TestSourceHandlerPage < Test::Unit::TestCase

  include Test::WebsiteHelper

  def setup
    super
    @website.blackboard.del_service(:templates_for_node)
    @website.blackboard.add_service(:templates_for_node) {|node| []}
    @obj = Webgen::SourceHandler::Page.new
    @root = Webgen::Node.new(@website.tree.dummy_root, '/', '/')
    @path = path_with_meta_info('/index.page') {StringIO.new('content')}
    @path.meta_info.update({'lang'=>'eo', 'test'=>'yes', 'sort_info'=>6})
    @website.blackboard.add_service(:source_paths) {{@path.path => @path}}
  end

  def test_create_node
    node = @obj.create_node(@path.dup)

    assert_not_nil(node)
    assert_equal('/index.eo.html', node.path)
    assert_equal(@obj.class.name, node.node_info[:processor])
    assert_equal('Index', node['title'])
    assert_equal('yes', node['test'])
    assert_equal(6, node['sort_info'])
    assert_equal(Webgen::LanguageManager.language_for_code('epo'), node.lang)

    assert_equal(node, @obj.create_node(@path.dup))

    @root.tree.delete_node(node)
    path = @path.dup
    def path.changed?
      false
    end
    @obj.create_node(path)
  end

  def test_content
    node = @obj.create_node(@path)
    assert_equal("content", @obj.content(node))
  end

  def test_render_node
    node = @obj.create_node(@path)
    assert_equal("content", @obj.render_node(node))
    assert_raise(RuntimeError) { @obj.render_node(node, 'other') }
  end

  def test_meta_info_changed
    node = @obj.create_node(@path)
    @website.blackboard.dispatch_msg(:node_meta_info_changed?, node)
    assert(!node.meta_info_changed?)

    @path.instance_eval { @io = Webgen::Path::SourceIO.new {StringIO.new("---\ntitle: test\n---\ncontent")} }
    @website.blackboard.dispatch_msg(:node_meta_info_changed?, node)
    assert(node.meta_info_changed?)

    # Remove path from which node is created, meta info should naturally change
    @root.tree.delete_node(node)
    node = @obj.create_node(@path)
    @website.blackboard.del_service(:source_paths)
    @website.blackboard.add_service(:source_paths) { {} }
    @website.blackboard.dispatch_msg(:node_meta_info_changed?, node)
    assert(node.meta_info_changed?)
  end

end
