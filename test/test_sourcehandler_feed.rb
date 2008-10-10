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
    @nodes = {
      :root => root = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/', {'index_path' => 'index.html'}),
      :file1_en => Webgen::Node.new(root, '/file1.en.html', 'file1.html', {'lang' => 'en', 'in_menu' => true, 'modified_at' => Time.now}),
      :index_en => Webgen::Node.new(root, '/index.en.html', 'index.html', {'lang' => 'en', 'modified_at' => Time.now - 1, 'author' => 'test'}),
    }
    @nodes[:index_en].node_info[:page] = Webgen::Page.from_data("--- name:content\nMyContent\n--- name:abstract\nRealContent")
    @obj = Webgen::SourceHandler::Feed.new
    @path = path_with_meta_info('/test.feed', {}, @obj.class.name) {StringIO.new(FEED_CONTENT)}
  end

  def test_create_node
    atom_node, rss_node = @obj.create_node(@nodes[:root], @path)

    assert_not_nil(atom_node)
    assert_not_nil(rss_node)
    assert_kind_of(Webgen::Page, atom_node.node_info[:feed])
    assert_equal('atom', atom_node.node_info[:feed_type])
    assert_equal('rss', rss_node.node_info[:feed_type])

    assert_equal([atom_node, rss_node], @obj.create_node(@nodes[:root], @path))
  end

  def test_content
    atom_node, rss_node = @obj.create_node(@nodes[:root], @path)
    assert_equal('hallo', rss_node.content)
    assert(atom_node.content =~ /Thomas Leitner/)
    assert(atom_node.content =~ /RealContent/)
  end

  def test_feed_entries
    atom_node, rss_node = @obj.create_node(@nodes[:root], @path)
    assert_equal([@nodes[:index_en]], atom_node.feed_entries)
    assert_equal([@nodes[:index_en]], rss_node.feed_entries)
  end

  def test_node_changed
    atom_node, rss_node = @obj.create_node(@nodes[:root], @path)
    assert(atom_node.changed?)

    atom_node.content # populate cache
    @website.cache.old_data.update(@website.cache.new_data)

    atom_node.unflag(:dirty)
    assert(atom_node.changed?)

    atom_node.unflag(:dirty)
    @nodes[:file1_en].unflag(:dirty)
    @nodes[:index_en].unflag(:dirty)
    assert(!atom_node.changed?)

    atom_node['entries'] = 'file.*.html'
    assert(atom_node.changed?)
  end

end
