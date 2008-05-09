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
    @temp = Object.new
    @temp.extend(Webgen::SourceHandler::Base)
  end

  def test_node_exists
    @tree = Webgen::Tree.new
    node = Webgen::Node.new(@tree.dummy_root, 'test/', 'test', {'lang' => 'de', :test => :value})
    child_de = Webgen::Node.new(node, 'test/somename.html', 'somename.page', {'lang' => 'de'})
    frag_de = Webgen::Node.new(child_de, '#data1', '#othertest')

    assert_equal(child_de, @temp.node_exists?(node, Webgen::Path.new('somename.de.page')))
    assert_equal(child_de, @temp.node_exists?(node, Webgen::Path.new('other.page'), @temp.output_path(node, Webgen::Path.new('somename.html'))))
    assert_equal(frag_de, @temp.node_exists?(child_de, Webgen::Path.new('#othertest')))
    assert_equal(nil, @temp.node_exists?(node, Webgen::Path.new('unknown')))
  end

  def test_output_path
    @tree = Webgen::Tree.new
    node = Webgen::Node.new(@tree.dummy_root, 'test/', 'test', {'lang' => 'de', :test => :value})

    path = Webgen::Path.new('path.html')
    assert_equal('test/path.html', @temp.output_path(node, path, [:parent, :cnbase, ['.', :lang], :ext]))
    path = Webgen::Path.new('path.en.html')
    assert_equal('test/path.html', @temp.output_path(node, path, [:parent, :cnbase, ['.', :lang], :ext]))
    path = Webgen::Path.new('path.eo.html')
    assert_equal('test/path.eo.html', @temp.output_path(node, path, [:parent, :cnbase, ['.', :lang], :ext]))
    path = Webgen::Path.new('dir/')
    assert_equal('test/dir/', @temp.output_path(node, path, [:parent, :cnbase, ['.', :lang], :ext]))

    other = Webgen::Node.new(node, 'test/path.html', 'other.page')
    path = Webgen::Path.new('path.html')
    assert_equal('test/path.html', @temp.output_path(node, path, [:parent, :cnbase, ['.', :lang], :ext]))
    path = Webgen::Path.new('path.en.html')
    assert_equal('test/path.en.html', @temp.output_path(node, path, [:parent, :cnbase, ['.', :lang], :ext]))

    path = Webgen::Path.new('/')
    assert_equal('/', @temp.output_path(@tree.dummy_root, path, [:parent, :cnbase, ['.', :lang], :ext]))
  end

end
