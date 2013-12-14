# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/path_handler/feed'
require 'webgen/content_processor'
require 'webgen/node_finder'
require 'webgen/path'
require 'webgen/version'

class TestPathHandlerFeed < Minitest::Test

  include Webgen::TestHelper

  FEED_CONTENT = <<EOF
---
entries:
  :alcn: "*.html"
author: Thomas Leitner
content_block_name: abstract
--- name:rss_template
hallo
EOF

  def setup
    setup_website('website.lang' => 'en', 'website.base_url' => 'http://example.com')
    @website.ext.node_finder = Webgen::NodeFinder.new(@website)

    @feed = Webgen::PathHandler::Feed.new(@website)

    root = Webgen::PathHandler::Base::Node.new(@website.tree.dummy_root, '/', '/')
    @index_en = RenderNode.new("--- name:content\nMyContent\n--- name:abstract\nRealContent", root,
                               'index.html', '/index.en.html', {'lang' => 'en', 'modified_at' => Time.now - 1, 'author' => 'test'})
    @file_en = RenderNode.new("--- name:content\nCContent\n--- name:abstract\nAContent", root,
                              'file.html', '/file.en.html', {'lang' => 'en', 'modified_at' => Time.now - 2})

    template_data = File.read(File.join(Webgen::Utils.data_dir, 'passive_sources', 'templates', 'feed.template'))
    RenderNode.new(template_data, root, 'feed.template', '/templates/feed.template')

    @path = Webgen::Path.new('/test_feed', 'dest_path' => '<parent><basename><ext>') { StringIO.new(FEED_CONTENT) }
    @path.meta_info.update(Webgen::Page.from_data(FEED_CONTENT).meta_info)
    @path_blocks = Webgen::Page.from_data(FEED_CONTENT).blocks
  end

  def create_nodes
    @path['version'] = 'atom'
    atom_node = @feed.create_nodes(@path.dup, @path_blocks)
    @path['version'] = 'rss'
    rss_node = @feed.create_nodes(@path.dup, @path_blocks)
    [atom_node, rss_node]
  end

  def test_create_node
    atom_node, rss_node = create_nodes

    refute_nil(atom_node)
    refute_nil(rss_node)
    refute_nil(atom_node.node_info[:blocks])
    assert_equal('atom', atom_node['version'])
    assert_equal('rss', rss_node['version'])

    assert_raises(Webgen::NodeCreationError) do
      path = Webgen::Path.new('/test_feed_2') { StringIO.new("---\nunknow: yes") }
      @feed.create_nodes(path, 'unused')
    end

    @path['version'] = 'atom'
    @path['cn'] = 'atom.xml'
    atom_node = @feed.create_nodes(@path.dup, @path_blocks)
    assert_equal('atom.xml', atom_node.cn)
  end

  def test_content
    @website.ext.content_processor = Webgen::ContentProcessor.new
    @website.ext.content_processor.register('Erb')
    @website.ext.content_processor.register('Blocks')

    atom_node, rss_node = create_nodes
    assert_equal("hallo\n", @feed.content(rss_node))
    assert(@feed.content(atom_node) =~ /Thomas Leitner/)
    assert(@feed.content(atom_node) =~ /RealContent/)
  end

  def test_feed_entries
    atom_node, rss_node = create_nodes
    assert_equal([@index_en, @file_en], atom_node.feed_entries)
    assert_equal([@index_en, @file_en], rss_node.feed_entries)
  end

end
