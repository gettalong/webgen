# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/sourcehandler'
require 'stringio'

class TestSourceHandlerFeed < Test::Unit::TestCase

  include Test::WebsiteHelper

  FEED_CONTENT = <<EOF
---
site_url: http://example.com
entries: *.html
author: Thomas Leitner
content_block_name: abstract
--- name:rss_template
hallo
EOF
  def setup
    super
    shm = Webgen::SourceHandler::Main.new
    @website.blackboard.del_listener(:node_meta_info_changed?, shm.method(:meta_info_changed?))
    @website.config['passive_sources'] << ['/', "Webgen::Source::Resource", "webgen-passive-sources"]
    @nodes = {
      :root => root = Webgen::Node.new(@website.tree.dummy_root, '/', '/', {'index_path' => 'index.html'}),
      :file1_en => Webgen::Node.new(root, '/file1.en.html', 'file1.html', {'lang' => 'en', 'in_menu' => true, 'modified_at' => Time.now}),
      :index_en => Webgen::Node.new(root, '/index.en.html', 'index.html', {'lang' => 'en', 'modified_at' => Time.now - 1, 'author' => 'test'}),
      :file2_en => Webgen::Node.new(root, '/file2.en.html', 'file2.html', {'lang' => 'en', 'modified_at' => Time.now - 2}),
    }
    @nodes[:index_en].node_info[:page] = Webgen::Page.from_data("--- name:content\nMyContent\n--- name:abstract\nRealContent")
    @nodes[:file2_en].node_info[:page] = Webgen::Page.from_data("--- name:content\nCContent\n--- name:abstract\nAContent")
    @obj = Webgen::SourceHandler::Feed.new
    @path = path_with_meta_info('/test.feed', {}, @obj.class.name) {StringIO.new(FEED_CONTENT)}
  end

  def test_create_node
    atom_node, rss_node = @obj.create_node(@path)

    assert_not_nil(atom_node)
    assert_not_nil(rss_node)
    assert_kind_of(Webgen::Page, atom_node.node_info[:feed])
    assert_equal('atom', atom_node.node_info[:feed_type])
    assert_equal('rss', rss_node.node_info[:feed_type])

    assert_equal([atom_node, rss_node], @obj.create_node(@path))

    assert_raise(Webgen::NodeCreationError) do
      @obj.create_node(path_with_meta_info('/test.feed', {}, @obj.class.name) {StringIO.new("---\nsite_url: test\n---\n")})
    end
  end

  def test_content
    atom_node, rss_node = @obj.create_node(@path)
    assert_equal("hallo\n", rss_node.content)
    assert(atom_node.content =~ /Thomas Leitner/)
    assert(atom_node.content =~ /RealContent/)
  end

  def test_feed_entries
    atom_node, rss_node = @obj.create_node(@path)
    assert_equal([@nodes[:index_en], @nodes[:file2_en]], atom_node.feed_entries)
    assert_equal([@nodes[:index_en], @nodes[:file2_en]], rss_node.feed_entries)
  end

  def test_node_changed
    atom_node, rss_node = @obj.create_node(@path)
    assert(atom_node.changed?)

    atom_node.content # populate cache
    @website.cache.old_data.update(@website.cache.new_data)

    atom_node.unflag(:dirty)
    assert(atom_node.changed?)

    atom_node.unflag(:dirty)
    @nodes[:file1_en].unflag(:dirty)
    @nodes[:index_en].unflag(:dirty)
    @nodes[:file2_en].unflag(:dirty)
    @website.tree['/templates/atom_feed.template'].unflag(:dirty)
    assert(!atom_node.changed?)

    atom_node['entries'] = 'file.*.html'
    assert(atom_node.changed?)
  end

end
