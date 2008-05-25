require 'test/unit'
require 'helper'
require 'webgen/sourcehandler/page'
require 'stringio'

class TestBlock < Test::Unit::TestCase

  def test_render
    block = Webgen::Block.new('content', 'some content', {'pipeline' => 'test'})
    context = {:processors => {}}
    assert_raise(RuntimeError) { block.render(context) }
    context[:processors]['test'] = lambda {|context| context[:content] = context[:content].reverse + context[:block].name }
    assert_equal('some content'.reverse + 'content', block.render(context)[:content])
  end

end


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
    @path.meta_info.update({'lang'=>'eo', 'test'=>'yes', 'order_info'=>6})
  end

  def test_create_node
    node = @obj.create_node(@root, @path.dup)

    assert_not_nil(node)
    assert_equal('test/index.eo.html', node.path)
    assert_equal(@obj.class.name, node.node_info[:processor])
    assert_equal('Index', node['title'])
    assert_equal('yes', node['test'])
    assert_equal(6, node['order_info'])
    assert_equal(Webgen::LanguageManager.language_for_code('epo'), node.lang)

    assert_nil(@obj.create_node(@root, @path.dup))

    assert_raise(RuntimeError) { @obj.create_node(@root, path_with_meta_info('/other.page') { StringIO.new("---\:dfk")}) }
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

end
