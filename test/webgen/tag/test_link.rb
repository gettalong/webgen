# -*- encoding: utf-8 -*-

require 'helper'
require 'webgen/logger'
require 'webgen/context'
require 'webgen/node'
require 'webgen/tree'
require 'webgen/tag/link'

class TestTagLink < MiniTest::Unit::TestCase

  def test_call
    @obj = Webgen::Tag::Link
    website, @context = Test.setup_tag_test
    website.expect(:config, {'website.link_to_current_page' => false})
    website.expect(:tree, Webgen::Tree.new(website))
    website.expect(:logger, Logger.new(StringIO.new))
    website.ext.item_tracker = MiniTest::Mock.new
    def (website.ext.item_tracker).add(*args); end

    root = Webgen::Node.new(website.tree.dummy_root, '/', '/')
    node = Webgen::Node.new(root, 'file.html', '/file.html', {'lang' => 'en'})
    dir = Webgen::Node.new(root, 'dir/', '/dir/', 'proxy_path' => "index.html")
    file = Webgen::Node.new(dir, 'file.html', '/dir/file.html', {'lang' => 'en', 'title' => 'file'})
    Webgen::Node.new(dir, 'other.html', '/dir/other.output.html', {'lang' => 'de'})
    Webgen::Node.new(file, '#fragment', '/dir/file.html#fragment')
    dir2 = Webgen::Node.new(root, 'dir2/', '/dir2/', 'proxy_path' => "index.html")
    Webgen::Node.new(dir2, 'index.html', '/dir2/index.html')

    @context[:chain] = [node]
    @context[:config] = {'tag.link.attr' => {}}

    # no path set
    assert_tag_result('<span></span>', '')

    # invalid paths
    @context[:config]['tag.link.path'] = ':/asdf=-)'
    assert_raises(Webgen::RenderError) { @obj.call('link', '', @context) }

    # basic node resolving
    assert_tag_result('<a href="dir/file.html">file</a>', 'dir/file.html')
    @context[:config]['tag.link.attr'] = {'title' => 'other'}
    assert_tag_result('<a href="dir/file.html" title="other">file</a>', 'dir/file.html')
    @context[:config]['tag.link.attr'] = {}
    assert_tag_result('', 'dir/other.html')

    # non-existing fragments
    assert_tag_result('', 'file.html#hallo')

    # directory paths
    assert_tag_result('<a href="dir/"></a>', 'dir')
    assert_tag_result('<a href="dir2/index.html"></a>', 'dir2')
  end

  def assert_tag_result(result, path)
    @context[:config]['tag.link.path'] = path
    assert_equal(result, @obj.call('link', '', @context))
  end

end
