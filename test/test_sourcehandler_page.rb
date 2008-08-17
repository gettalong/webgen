require 'test/unit'
require 'helper'
require 'webgen/sourcehandler/page'
require 'stringio'

class TestSourceHandlerPage < Test::Unit::TestCase

  include Test::WebsiteHelper

  def setup
    super
    @website.blackboard.del_service(:templates_for_node)
    @website.blackboard.del_service(:parse_html_sections)
    @website.blackboard.del_service(:create_fragment_nodes)
    @website.blackboard.add_service(:templates_for_node) {|node| []}
    @website.blackboard.add_service(:parse_html_sections) {[]}
    @website.blackboard.add_service(:create_fragment_nodes) {nil}
    @obj = Webgen::SourceHandler::Page.new
    @root = Webgen::Node.new(Webgen::Tree.new.dummy_root, 'test/', 'test')
    @path = path_with_meta_info('/index.page') {StringIO.new('content')}
    @path.meta_info.update({'lang'=>'eo', 'test'=>'yes', 'sort_info'=>6})
    @website.blackboard.add_service(:source_paths) {{@path.path => @path}}
  end

  def test_create_node
    node = @obj.create_node(@root, @path.dup)

    assert_not_nil(node)
    assert_equal('test/index.eo.html', node.path)
    assert_equal(@obj.class.name, node.node_info[:processor])
    assert_equal('Index', node['title'])
    assert_equal('yes', node['test'])
    assert_equal(6, node['sort_info'])
    assert_equal(Webgen::LanguageManager.language_for_code('epo'), node.lang)
    assert_not_nil(@website.cache.permanent[:page_sections]['/test/index.eo.html'])

    assert_nil(@obj.create_node(@root, @path.dup))

    @root.tree.delete_node(node)
    path = @path.dup
    def path.changed?
      false
    end
    @obj.create_node(@root, path)
  end

  def test_content
    node = @obj.create_node(@root, @path)
    assert_equal("content", @obj.content(node))
  end

  def test_render_node
    node = @obj.create_node(@root, @path)
    assert_equal("content", @obj.render_node(node))
    assert_raise(RuntimeError) { @obj.render_node(node, 'other') }
  end

  def test_meta_info_changed
    node = @obj.create_node(@root, @path)
    @website.blackboard.dispatch_msg(:node_meta_info_changed?, node)
    assert(node.meta_info_changed?)

    node.dirty_meta_info = false
    @website.cache.restore(@website.cache.dump)
    @website.cache[[:sh_page_node_mi, node.absolute_lcn]]['modified_at'] = Time.now
    @website.blackboard.dispatch_msg(:node_meta_info_changed?, node)
    assert(!node.meta_info_changed?)
  end

end
