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
EOF

  def test_create_node
    obj = Webgen::SourceHandler::Virtual.new
    root = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/')
    shm = Webgen::SourceHandler::Main.new # for using service :create_nodes
    time = Time.now
    nodes = obj.create_node(root, path_with_meta_info('/virtuals', {'modified_at' => time}, obj.class.name) {StringIO.new(CONTENT)})

    nodes.each {|n| assert_equal('/virtuals', n.node_info[:src])}

    path_de = root.tree['/path.de.html']
    path_en = root.tree['/directory/path.en.html']
    dir = root.tree['/dir']
    assert_not_nil(path_de)
    assert_not_nil(dir)
    assert_not_nil(path_en)

    assert_equal('new title', path_en['title'])
    assert_equal(time, path_en['modified_at'])
    assert(path_en['no_output'])
    assert_equal('My Dir', dir['title'])
    assert_equal('directory/other.html', path_de.route_to(path_en))
    assert_equal('../path.de.html', dir.route_to(path_de))
    assert_equal('../directory/other.html', dir.route_to(path_en))

    assert_equal('http://www.example.com', root.tree['/api.html'].path)
    assert_equal('http://www.example.com', root.tree['/path.de.html'].route_to(root.tree['/api.html']))
  end

end
