# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/sourcehandler'
require 'stringio'

class TestSourceHandlerMetainfo < Test::Unit::TestCase

  include Test::WebsiteHelper

  class TestSH; include Webgen::SourceHandler::Base; end

  CONTENT=<<EOF
/default.*:
  title: new title
  before: valbef
---
/default.css:
  after: valaft

/other.page:
  title: Not Other
EOF

  def setup
    super
    @website.blackboard.add_service(:source_paths) do
      {'/default.css' => path_with_meta_info('/default.css') {StringIO.new('# header')},
        '/other.page' => path_with_meta_info('/other.page') {StringIO.new('other page')},
      }
    end

    @obj = Webgen::SourceHandler::Metainfo.new
    @root = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/')
    @node = @obj.create_node(@root, path_with_meta_info('/metainfo', {}, @obj.class.name) {StringIO.new(CONTENT)})
  end

  def test_create_node
    assert_equal({'/default.*' => {'title' => 'new title', 'before' => 'valbef'}}, @node.node_info[:mi_paths])
    assert_equal({'/default.css' => {'after' => 'valaft'},
                 '/other.page' => {'title' => 'Not Other'}}, @node.node_info[:mi_alcn])
  end

  def test_empty_metainfo_file
    node = @obj.create_node(@root, path_with_meta_info('/test', {}, @obj.class.name) {StringIO.new('')})
    assert_equal({}, node.node_info[:mi_paths])
    assert_equal({}, node.node_info[:mi_alcn])
  end

  def test_meta_info_changed
    other = TestSH.new.create_node(@root, path_with_meta_info('/default.css'))
    assert(!@obj.send(:meta_info_changed?, @node, other))
    assert(@obj.send(:meta_info_changed?, @node, other, :force))
    assert(!@obj.send(:meta_info_changed?, @node, other, :no_old_data))
  end

  def test_mark_all_matched_dirty
    other = TestSH.new.create_node(@root, path_with_meta_info('/default.css'))

    other.unflag(:dirty_meta_info)
    @obj.send(:mark_all_matched_dirty, @node)
    assert(!other.flagged(:dirty_meta_info))

    other.unflag(:dirty_meta_info)
    @obj.send(:mark_all_matched_dirty, @node, :force)
    assert(other.flagged(:dirty_meta_info))

    other.unflag(:dirty_meta_info)
    @obj.send(:mark_all_matched_dirty, @node, :no_old_data)
    assert(!other.flagged(:dirty_meta_info))
  end

  def test_before_node_created
    path = path_with_meta_info('/default.css')
    @website.blackboard.dispatch_msg(:before_node_created, @root, path)
    assert('valbef', path.meta_info['before'])
  end

  def test_after_node_created
    other = TestSH.new.create_node(@root, path_with_meta_info('/default.css'))
    @website.blackboard.dispatch_msg(:after_node_created, @node)
    assert('valaft', other['after'])
  end

  def test_before_node_deleted
    other = TestSH.new.create_node(@root, path_with_meta_info('/default.css'))
    @website.blackboard.dispatch_msg(:before_node_deleted, @node)
    assert(other.flagged(:dirty_meta_info))
    assert(@obj.nodes.empty?)
  end

  def test_node_meta_info_changed
    @node.unflag(:dirty_meta_info)
    @website.blackboard.dispatch_msg(:node_meta_info_changed?, @node)
    assert(!@node.flagged(:dirty_meta_info))

    @node.node_info[:mi_alcn] = @node.node_info[:mi_alcn].dup
    @node.node_info[:mi_alcn]['/*metainfo'] = {'other' => 'doit'}
    @website.blackboard.dispatch_msg(:node_meta_info_changed?, @node)
    assert(@node.flagged(:dirty_meta_info))
  end

  def test_content
    assert_nil(@obj.content(nil))
  end

  def test_deletion_of_metainfo
    other = TestSH.new.create_node(@root, path_with_meta_info('/other.page'))
    @website.blackboard.dispatch_msg(:after_node_created, other)
    assert_equal('Not Other', other['title'])

    @node.flag(:reinit)
    @node = @obj.create_node(@root, path_with_meta_info('/metainfo', {}, @obj.class.name) {StringIO.new("")})
    assert(other.flagged(:dirty_meta_info))
  end

end
