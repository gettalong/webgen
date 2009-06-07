# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/sourcehandler'
require 'stringio'

class TestSourceHandlerVirtual < Test::Unit::TestCase

  include Test::WebsiteHelper

  CONTENT=<<EOF
\\--- !omap
- path.de.html:

- /dir/file.html:

- /dir/:
    title: My Dir

- /directory/path.en.html:
    url: other.html
    title: new title

- api.html:
    url: http://www.example.com
    title: Absolute

- other.html:
    url: directory/path.en.html
    title: Nothing
EOF

  def setup
    super
    @obj = Webgen::SourceHandler::Virtual.new
    @root = Webgen::Node.new(@website.tree.dummy_root, '/', '/')
    shm = Webgen::SourceHandler::Main.new # for using service :create_nodes
    @time = Time.now
    @path = path_with_meta_info('/virtuals', {'modified_at' => @time}, @obj.class.name) {StringIO.new(CONTENT)}
    @nodes = @obj.create_node(@path)
    @website.blackboard.del_service(:source_paths)
    @website.blackboard.add_service(:source_paths) {{@path.path => @path}}
  end

  def test_create_node
    @nodes.each {|n| assert_equal('/virtuals', n.node_info[:src])}

    path_de = @root.tree['/path.de.html']
    path_en = @root.tree['/directory/path.en.html']
    dir = @root.tree['/dir/']
    assert_not_nil(path_de)
    assert_not_nil(dir)
    assert_not_nil(path_en)

    assert_equal('new title', path_en['title'])
    assert_equal(@time, path_en['modified_at'])
    assert(path_en['no_output'])
    assert_equal('My Dir', dir['title'])
    assert_equal('directory/other.html', path_de.route_to(path_en))
    assert_equal('../path.de.html', dir.route_to(path_de))
    assert_equal('../directory/other.html', dir.route_to(path_en))

    assert_equal('http://www.example.com', @root.tree['/api.html'].path)
    assert_equal('http://www.example.com', @root.tree['/path.de.html'].route_to(@root.tree['/api.html']))
  end

  def test_meta_info_changed
    # Nothing done, nothing should have changed
    path_de = @root.tree['/path.de.html']
    @obj.send(:node_meta_info_changed?, path_de)
    assert(!path_de.flagged?(:dirty_meta_info))

    # Change data, meta info should have changed
    @path.instance_eval { @io = Webgen::Path::SourceIO.new {StringIO.new("path.de.html:\n  title: hallo")} }
    @obj.send(:node_meta_info_changed?, path_de)
    assert(path_de.flagged?(:dirty_meta_info))

    # Reinit node, meta info of path_de should not change, #create_node should only return one node
    path_de.flag(:reinit)
    assert(1, @obj.create_node(@path).length)
    @obj.send(:node_meta_info_changed?, path_de)
    assert(!path_de.flagged?(:dirty_meta_info))

    # Remove data, meta info should have changed
    @path.instance_eval { @io = Webgen::Path::SourceIO.new {StringIO.new("patha.de.html:\n  title: hallo")} }
    @obj.send(:node_meta_info_changed?, path_de)
    assert(path_de.flagged?(:dirty_meta_info))

    # Remove path from which virtual node is created, meta info should naturally change
    @root.tree.delete_node(path_de)
    @path.instance_eval { @io = Webgen::Path::SourceIO.new {StringIO.new("path.de.html:\n  title: hallo")} }
    @obj.create_node(@path)
    path_de = @root.tree['/path.de.html']
    @website.blackboard.del_service(:source_paths)
    @website.blackboard.add_service(:source_paths) { {} }
    @obj.send(:node_meta_info_changed?, path_de)
    assert(path_de.meta_info_changed?)
  end

end
