# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/content_processor/fragments'
require 'yaml'

class TestContentProcessorFragments < Minitest::Test

  include Webgen::TestHelper

  TEST_CONTENT=<<EOF
- data: |
    <h1 id="test" style="test">Test</h1>
    <h2 id="other">test</h2>
    <h1>nothing</h1>
    <h1 id="third">test</h1>
  sections:
    - [1, test, Test]
    - [2, other, test]
    - [1, third, test]

- data: |
    <h1 id="test">Test</h1>
    <h2 id="other">test</h2>
    <h3 id='non'>other</h3>
    <h1 id="third">test</h1>
    <h3 id='four'>fourth</h3>
  sections:
    - [1, test, Test]
    - [2, other, test]
    - [3, non, other]
    - [1, third, test]
    - [3, four, fourth]
EOF

  def setup
    @cp = Webgen::ContentProcessor::Fragments
  end

  def test_static_parse_html_headers
    YAML::load(TEST_CONTENT).each do |data|
      sections = @cp.parse_html_headers(data['data'])
      check_sections(sections, data['sections'])
    end
  end

  def check_sections(sections, valid)
    sections.each do |level, id, title, subsecs|
      assert_equal(valid.shift, [level, id, title])
      check_sections(subsecs, valid)
    end
  end

  def test_static_call
    setup_website
    @website.ext.path_handler = Object.new
    def (@website.ext.path_handler).create_secondary_nodes(path, body, source_node)
      @proc.call(path, body, source_node)
    end
    create_secondary_nodes = lambda do |path, body, source_node|
      assert_equal('', body)
      assert_equal('copy', path['handler'])
      assert_equal(@website.tree['/test.html'].alcn, source_node)
      parent = @website.tree[path.meta_info['parent_alcn']]
      [Webgen::Node.new(parent, path.cn, path.alcn, path.meta_info)]
    end
    @website.ext.path_handler.instance_variable_set(:@proc, create_secondary_nodes)

    root = Webgen::Node.new(@website.tree.dummy_root, '/', '/')
    node = Webgen::Node.new(root, 'test.html', '/test.html')
    node.node_info[:src] = '/test.html'

    context = Webgen::Context.new(@website, :chain => [node])
    context.content = YAML::load(TEST_CONTENT).first['data']
    @cp.call(context)
    refute_nil(root.tree['/test.html#test'])
    refute_nil(root.tree['/test.html#other'])
    refute_nil(root.tree['/test.html#third'])
    assert_equal(node, node.resolve('#test').parent)
    assert_equal(node.resolve('#test'), node.resolve('#other').parent)

    assert_equal(6, root.tree.node_access[:alcn].length)
    root.tree.delete_node('/test.html#test')

    context[:block_name] = 'content'
    context.content = '<h1 id="mytest">Test</h1>'
    @cp.call(context)
    refute_nil(root.tree['/test.html#mytest'])
    root.tree.delete_node(root.tree['/test.html#mytest'])

    context[:block_name] = 'other'
    @cp.call(context)
    assert_nil(root.tree['/test.html#mytest'])
  end

end
