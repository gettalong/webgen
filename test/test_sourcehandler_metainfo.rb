require 'test/unit'
require 'helper'
require 'webgen/sourcehandler/metainfo'
require 'stringio'

class TestSourceHandlerMetainfo < Test::Unit::TestCase

  include Test::WebsiteHelper

  class TestSH; include Webgen::SourceHandler::Base; end

  CONTENT=<<EOF
**/*:
  title: new title
  before: valbef
---
**/*/:
  after: valaft
EOF

  def setup
    super
    @website.blackboard.add_service(:source_paths) do
      {'/default.css' => path_with_meta_info('/default.css') {StringIO.new('# header')}}
    end

    @obj = Webgen::SourceHandler::Metainfo.new
    @root = Webgen::Node.new(Webgen::Tree.new.dummy_root, 'test/', '/')
    @node = @obj.create_node(@root, path_with_meta_info('/metainfo', {}, @obj.class.name) {StringIO.new(CONTENT)})
  end

  def test_create_node
    assert_equal({'/**/*' => {'title' => 'new title', 'before' => 'valbef'}}, @node.node_info[:mi_paths])
    assert_equal({'/**/*' => {'after' => 'valaft'}}, @node.node_info[:mi_alcn])
  end

  def test_mark_all_matched_dirty
    other = TestSH.new.create_node(@root, path_with_meta_info('/default.css'))
    other.dirty = false
    @obj.send(:mark_all_matched_dirty, @node)
    assert(other.dirty)
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
    other.dirty = false
    @website.blackboard.dispatch_msg(:before_node_deleted, @node)
    assert(other.dirty)
  end

  def test_node_changed
    @node.dirty = false
    @website.blackboard.dispatch_msg(:node_changed?, @node)
    assert(!@node.dirty)

    @node.dirty = true
    other = TestSH.new.create_node(@root, path_with_meta_info('/default.css'))
    other.dirty = false
    @website.blackboard.dispatch_msg(:node_changed?, other)
    assert(other.dirty)
  end

  def test_content
    assert_nil(@obj.content(nil))
  end

end
