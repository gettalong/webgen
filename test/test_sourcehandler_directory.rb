# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/sourcehandler'
require 'stringio'

class TestSourceHandlerDirectory < Test::Unit::TestCase

  include Test::WebsiteHelper

  def test_create_node
    @obj = Webgen::SourceHandler::Directory.new
    root = Webgen::Node.new(Webgen::Tree.new.dummy_root, 'test/', 'test')
    node = @obj.create_node(root, path_with_meta_info('/dir/', {:key => :value}) {StringIO.new('')})
    assert_not_nil(node)
    assert_equal(:value, node[:key])

    node.flag(:reinit)
    assert_equal(node, @obj.create_node(root, path_with_meta_info('/dir/', {:key => :other}) {StringIO.new('')}))
    assert_equal(:other, node[:key])
  end

  def test_create_directories
    @obj = Webgen::SourceHandler::Directory.new
    shm = Webgen::SourceHandler::Main.new # for using service :create_nodes
    root = Webgen::Node.new(Webgen::Tree.new.dummy_root, 'test/', 'test')
    dir = @obj.create_node(root, path_with_meta_info('/dir/'))

    assert_equal(dir, @obj.create_directories(root, '/dir/', path_with_meta_info('/test')))
    assert_equal(dir, @obj.create_directories(root, 'dir/', path_with_meta_info('/test')))
    assert_equal(dir, @obj.create_directories(root, 'dir', path_with_meta_info('/test')))

    which = @obj.create_directories(root, 'dir/under/which', path_with_meta_info('/test'))
    assert_equal(which, @obj.create_directories(root, 'dir/under/which', path_with_meta_info('/test')))
  end

  def test_content
    assert_equal('', Webgen::SourceHandler::Directory.new.content(nil))
  end

end
