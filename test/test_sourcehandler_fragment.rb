# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/sourcehandler'
require 'stringio'

class TestSourceHandlerFragment < Test::Unit::TestCase

  include Test::WebsiteHelper

  TEST_CONTENT=<<EOF
- data: |
    <h1 id="test">Test</h1>
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

  def test_parse_html_headers
    @obj = Webgen::SourceHandler::Fragment.new
    YAML::load(TEST_CONTENT).each do |data|
      sections = @obj.parse_html_headers(data['data'])
      check_sections(sections, data['sections'])
    end
  end

  def test_create_fragment_nodes
    @obj = Webgen::SourceHandler::Fragment.new
    root = Webgen::Node.new(Webgen::Tree.new.dummy_root, 'test/', 'test')
    path = path_with_meta_info('hallo.html') {StringIO.new('')}
    node = @obj.create_node(root, path)
    @website.blackboard.add_service(:create_nodes, method(:create_nodes_service))

    sections = @obj.parse_html_headers(YAML::load(TEST_CONTENT).first['data'])
    @obj.create_fragment_nodes(sections, node, path, 'true')
    assert_equal(node, node.resolve('#test').parent)
    assert_equal(node.resolve('#test'), node.resolve('#other').parent)
  end

  def create_nodes_service(tree, alcn, path, sh)
    [yield(tree[alcn], path_with_meta_info(path.path))]
  end

  def check_sections(sections, valid)
    sections.each do |level, id, title, subsecs|
      assert_equal(valid.shift, [level, id, title])
      check_sections(subsecs, valid)
    end
  end

end
