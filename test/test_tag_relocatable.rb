require 'test/unit'
require 'helper'
require 'webgen/tree'
require 'webgen/contentprocessor'
require 'webgen/tag/relocatable'

class TestTagRelocatable < Test::Unit::TestCase

  include Test::WebsiteHelper

  def setup
    super
    @obj = Webgen::Tag::Relocatable.new
  end

  def call(context)
    @obj.call('relocatable', '', context)
  end

  def test_call
    root = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/')
    node = Webgen::Node.new(root, '/file.html', 'file.html')
    dir = Webgen::Node.new(root, '/dir/', 'dir/', 'index_path' => "index.html")
    file = Webgen::Node.new(dir, '/dir/file.html', 'file.html')
    Webgen::Node.new(file, '/dir/file.html#fragment', '#fragment')
    dir2 = Webgen::Node.new(root, '/dir2/', 'dir2/', 'index_path' => "index.html")
    Webgen::Node.new(dir2, '/dir2/index.html', 'index.html')

    context = Webgen::ContentProcessor::Context.new(:chain => [node])

    # basic node resolving
    @obj.set_params('tag.relocatable.path' => 'dir/file.html')
    assert_equal('dir/file.html', call(context))

    # non-existing fragments
    @obj.set_params('tag.relocatable.path' => 'file.html#hallo')
    assert_equal('', call(context))

    # absolute paths
    @obj.set_params('tag.relocatable.path' => 'http://test.com')
    assert_equal('http://test.com', call(context))

    # directory paths
    @obj.set_params('tag.relocatable.path' => 'dir')
    assert_equal('dir/', call(context))
    @obj.set_params('tag.relocatable.path' => 'dir2')
    assert_equal('dir2/index.html', call(context))

    # invalid paths
    @obj.set_params('tag.relocatable.path' => ':/asdf=-)')
    assert_equal('', call(context))
  end

end
