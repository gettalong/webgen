# -*- encoding: utf-8 -*-

require 'helper'
require 'webgen/logger'
require 'webgen/context'
require 'webgen/node'
require 'webgen/tree'
require 'webgen/tag/relocatable'

class TestTagRelocatable < MiniTest::Unit::TestCase

  def test_call
    @obj = Webgen::Tag::Relocatable
    website, @context = Test.setup_tag_test
    website.expect(:tree, Webgen::Tree.new(website))
    website.expect(:logger, Logger.new(StringIO.new))
    website.ext.item_tracker = MiniTest::Mock.new
    def (website.ext.item_tracker).add(*args); end

    root = Webgen::Node.new(website.tree.dummy_root, '/', '/')
    node = Webgen::Node.new(root, 'file.html', '/file.html', {'lang' => 'en'})
    dir = Webgen::Node.new(root, 'dir/', '/dir/', 'proxy_path' => "index.html")
    file = Webgen::Node.new(dir, 'file.html', '/dir/file.html', {'lang' => 'en'})
    Webgen::Node.new(dir, 'other.html', '/dir/other.output.html', {'lang' => 'de'})
    Webgen::Node.new(file, '#fragment', '/dir/file.html#fragment')
    dir2 = Webgen::Node.new(root, 'dir2/', '/dir2/', 'proxy_path' => "index.html")
    Webgen::Node.new(dir2, 'index.html', '/dir2/index.html')

    @context[:chain] = [node]

    # basic node resolving
    assert_tag_result('dir/file.html', 'dir/file.html')
    assert_tag_result('', 'dir/other.html')
    assert_tag_result('dir/other.output.html', 'dir/other.de.html')

    # non-existing fragments
    assert_tag_result('', 'file.html#hallo')

    # absolute paths
    assert_tag_result('http://test.com', 'http://test.com')

    # directory paths
    assert_tag_result('dir/', 'dir')
    assert_tag_result('dir2/index.html', 'dir2')

    # invalid paths
    @context[:config] = {'tag.relocatable.path' => ':/asdf=-)'}
    assert_raises(Webgen::RenderError) { @obj.call('relocatable', '', @context) }
  end

  def assert_tag_result(result, path)
    @context[:config] = {'tag.relocatable.path' => path}
    assert_equal(result, @obj.call('relocatable', '', @context))
  end

end
