require 'test/unit'
require 'helper'
require 'webgen/tree'
require 'webgen/node'
require 'webgen/path'
require 'webgen/sourcehandler/base'

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
    assert_equal(frag_de, @obj.node_exists?(child_de, path_with_meta_info('#othertest')))
    assert_equal(nil, @obj.node_exists?(node, path_with_meta_info('unknown')))
  end

  def test_output_path
    @tree = Webgen::Tree.new
    node = Webgen::Node.new(@tree.dummy_root, 'test/', 'test', {'lang' => 'de', :test => :value})

    path = Webgen::Path.new('path.html')
    assert_equal('test/path.html', @obj.output_path(node, path, [:parent, :cnbase, ['.', :lang], :ext]))
    path = Webgen::Path.new('path.en.html')
    assert_equal('test/path.html', @obj.output_path(node, path, [:parent, :cnbase, ['.', :lang], :ext]))
    path = Webgen::Path.new('path.eo.html')
    assert_equal('test/path.eo.html', @obj.output_path(node, path, [:parent, :cnbase, ['.', :lang], :ext]))
    path = Webgen::Path.new('dir/')
    assert_equal('test/dir/', @obj.output_path(node, path, [:parent, :cnbase, ['.', :lang], :ext]))

    other = Webgen::Node.new(node, 'test/path.html', 'other.page')
    path = Webgen::Path.new('path.html')
    assert_equal('test/path.html', @obj.output_path(node, path, [:parent, :cnbase, ['.', :lang], :ext]))
    path = Webgen::Path.new('path.en.html')
    assert_equal('test/path.en.html', @obj.output_path(node, path, [:parent, :cnbase, ['.', :lang], :ext]))

    path = Webgen::Path.new('/')
    assert_equal('/', @obj.output_path(@tree.dummy_root, path, [:parent, :cnbase, ['.', :lang], :ext]))
    assert_equal('hallo/', @obj.output_path(@tree.dummy_root, path, [:parent, 'hallo', 56]))
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
