require 'test/unit'
require 'helper'
require 'webgen/tree'
require 'webgen/node'
require 'webgen/path'
require 'webgen/sourcehandler'
require 'time'

class TestSourceHandlerBase < Test::Unit::TestCase

  include Test::WebsiteHelper

  def setup
    super
    @obj = Object.new
    @obj.extend(Webgen::SourceHandler::Base)
  end

  def test_node_exists
    @tree = Webgen::Tree.new
    node = Webgen::Node.new(@tree.dummy_root, 'test/', 'test', {'lang' => 'de', :test => :value})
    child_de = Webgen::Node.new(node, 'test/somename.html', 'somename.page', {'lang' => 'de'})
    frag_de = Webgen::Node.new(child_de, '#data1', '#othertest')

    assert_equal(child_de, @obj.node_exists?(node, path_with_meta_info('somename.de.page')))
    assert_equal(child_de, @obj.node_exists?(node, path_with_meta_info('other.page'), @obj.output_path(node, path_with_meta_info('somename.html'))))
    assert_equal(false, @obj.node_exists?(node, path_with_meta_info('somename.en.page', {'no_output' => true}),
                                          @obj.output_path(node, path_with_meta_info('somename.html'))))
    assert_equal(frag_de, @obj.node_exists?(child_de, path_with_meta_info('#othertest')))
    assert_equal(nil, @obj.node_exists?(node, path_with_meta_info('unknown')))
  end

  def test_output_path
    node = Webgen::Node.new(Webgen::Tree.new.dummy_root, 'test/', 'test')
    assert_raise(RuntimeError) { @obj.output_path(node, path_with_meta_info('test.page', 'output_path' => 'non'))}
  end

  def test_standard_output_path
    @tree = Webgen::Tree.new
    node = Webgen::Node.new(@tree.dummy_root, 'test/', 'test', {'lang' => 'de', :test => :value})

    path = path_with_meta_info('path.html')
    assert_equal('test/path.html', @obj.output_path(node, path))
    path = path_with_meta_info('path.en.html')
    assert_equal('test/path.html', @obj.output_path(node, path))
    path = path_with_meta_info('path.eo.html')
    assert_equal('test/path.eo.html', @obj.output_path(node, path))
    path = path_with_meta_info('dir/')
    assert_equal('test/dir/', @obj.output_path(node, path))

    other = Webgen::Node.new(node, 'test/path.html', 'other.page')
    path = path_with_meta_info('path.html')
    assert_equal('test/path.html', @obj.output_path(node, path))
    path = path_with_meta_info('path.en.html')
    assert_equal('test/path.en.html', @obj.output_path(node, path))

    path = path_with_meta_info('#frag')
    assert_equal('test/path.html#frag', @obj.output_path(other, path))
    frag = Webgen::Node.new(other, 'test/path.html#frag', '#frag')
    path = path_with_meta_info('#frag1')
    assert_equal('test/path.html#frag1', @obj.output_path(frag, path))

    path = path_with_meta_info('/')
    assert_equal('/', @obj.output_path(@tree.dummy_root, path))
    path = path_with_meta_info('/', 'output_path_style' => [:parent, 'hallo', 56])
    assert_equal('hallo/', @obj.output_path(@tree.dummy_root, path))

    assert_raise(RuntimeError) do
      path = path_with_meta_info('path.html', 'output_path_style' => [:parent, :year, '/', :month, '/', :cnbase, :ext])
      @obj.output_path(node, path)
    end
    time = Time.parse('2008-09-04 08:15')
    path = path_with_meta_info('path.html', 'output_path_style' => [:parent, :year, '/', :month, '/', :day, '-', :cnbase, :ext],
                               'created_at' => time)
    assert_equal('test/2008/09/04-path.html', @obj.output_path(node, path))
  end

  def test_content
    assert_nil(@obj.content(nil))
  end

  def test_page_from_path
    path = path_with_meta_info('/other.page', {'key' => 'value'}) { StringIO.new("---\nkey: value1\n---\ncontent")}
    page = @obj.page_from_path(path)
    assert_equal('content', page.blocks['content'].content)
    assert_equal('value1', path.meta_info['key'])

    path = path_with_meta_info('/other.page') { StringIO.new("---\:dfk")}
    assert_raise(RuntimeError) { @obj.page_from_path(path) }
  end

end
