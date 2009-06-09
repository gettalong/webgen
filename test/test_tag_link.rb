# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/tree'
require 'webgen/contentprocessor'
require 'webgen/tag'

class TestTagLink < Test::Unit::TestCase

  include Test::WebsiteHelper

  def setup
    super
    @obj = Webgen::Tag::Link.new
  end

  def call(context)
    @obj.call('link', '', context)
  end

  def test_call
    root = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/')
    node = Webgen::Node.new(root, '/file.html', 'file.html', {'lang' => 'en'})
    dir = Webgen::Node.new(root, '/dir/', 'dir/', 'index_path' => "index.html")
    file = Webgen::Node.new(dir, '/dir/file.html', 'file.html', {'lang' => 'en', 'title' => 'Dir/File'})
    Webgen::Node.new(dir, '/dir/other.de.html', 'other.html', {'lang' => 'de'})
    Webgen::Node.new(file, '/dir/file.html#fragment', '#fragment')
    dir2 = Webgen::Node.new(root, '/dir2/', 'dir2/', 'index_path' => "index.html")
    Webgen::Node.new(dir2, '/dir2/index.html', 'index.html')

    context = Webgen::Context.new(:chain => [node])

    # no path set
    node.unflag(:dirty)
    @obj.set_params('tag.link.path' => nil)
    assert_equal('<span></span>', call(context))
    assert(!node.flagged?(:dirty))

    # invalid paths
    @obj.set_params('tag.link.path' => ':/asdf=-)')
    assert_equal('', call(context))
    assert(node.flagged?(:dirty))

    # basic node resolving
    @obj.set_params('tag.link.path' => 'dir/file.html')
    assert_equal('<a href="dir/file.html">Dir/File</a>', call(context))
    @obj.set_params('tag.link.path' => 'dir/file.html', 'tag.link.attr' => {'title' => 'other'})
    assert_equal('<a href="dir/file.html" title="other">Dir/File</a>', call(context))
    @obj.set_params('tag.link.path' => 'dir/other.html')
    assert_equal('', call(context))

    # non-existing fragments
    @obj.set_params('tag.link.path' => 'file.html#hallo')
    assert_equal('', call(context))

    # directory paths
    @obj.set_params('tag.link.path' => 'dir')
    assert_equal('<a href="dir/"></a>', call(context))
    @obj.set_params('tag.link.path' => 'dir2')
    assert_equal('<a href="dir2/index.html"></a>', call(context))

    # used node information correctly set
    node.node_info[:used_meta_info_nodes] = Set.new
    @obj.set_params('tag.link.path' => 'dir/file.html')
    call(context)
    assert(Set.new([file.alcn]), node.node_info[:used_meta_info_nodes])
  end

end
