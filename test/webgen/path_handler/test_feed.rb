# -*- encoding: utf-8 -*-

require 'helper'
require 'ostruct'
require 'logger'
require 'stringio'
require 'webgen/path_handler/feed'
require 'webgen/content_processor'
require 'webgen/node_finder'
require 'webgen/tree'
require 'webgen/node'
require 'webgen/path'
require 'webgen/website'

class TestPathHandlerFeed < MiniTest::Unit::TestCase

  FEED_CONTENT = <<EOF
---
rss: true
atom: true
site_url: http://example.com
entries:
  :alcn: "*.html"
author: Thomas Leitner
content_block_name: abstract
--- name:rss_template
hallo
EOF

  def setup
    @website = MiniTest::Mock.new
    @website.expect(:tree, Webgen::Tree.new(@website))
    @website.expect(:logger, Logger.new(StringIO.new))
    @website.expect(:config, {'website.lang' => 'en'})
    @website.expect(:ext, OpenStruct.new)
    @website.ext.item_tracker = MiniTest::Mock.new
    def (@website.ext.item_tracker).add(*args); end
    @website.ext.node_finder = Webgen::NodeFinder.new(@website)

    @feed = Webgen::PathHandler::Feed.new(@website)

    @nodes = {
      :root => root = Webgen::Node.new(@website.tree.dummy_root, '/', '/'),
      :index_en => Test::RenderNode.new(root, 'index.html', '/index.en.html', {'lang' => 'en', 'modified_at' => Time.now - 1, 'author' => 'test'}),
      :file2_en => Test::RenderNode.new(root, 'file2.html', '/file2.en.html', {'lang' => 'en', 'modified_at' => Time.now - 2}),
    }
    @nodes[:index_en].node_info[:blocks] = Webgen::Page.from_data("--- name:content\nMyContent\n--- name:abstract\nRealContent").blocks
    @nodes[:file2_en].node_info[:blocks] = Webgen::Page.from_data("--- name:content\nCContent\n--- name:abstract\nAContent").blocks

    @template = Test::RenderNode.new(@nodes[:root], 'feed.template', '/templates/feed.template')
    template_data = File.read(File.join(Webgen.data_dir, 'passive_sources', 'templates', 'feed.template'))
    template_page = Webgen::Page.from_data(template_data)
    @template.node_info[:blocks] = template_page.blocks
    @template.meta_info.update(template_page.meta_info)

    @path = Webgen::Path.new('/test_feed', 'dest_path' => '<parent><basename><ext>') { StringIO.new(FEED_CONTENT) }
    @path.meta_info.update(Webgen::Page.from_data(FEED_CONTENT).meta_info)
  end

  def test_create_node
    atom_node, rss_node = @feed.create_nodes(@path, Webgen::Page.from_data(@path.data).blocks)

    refute_nil(atom_node)
    refute_nil(rss_node)
    refute_nil(atom_node.node_info[:blocks])
    assert_equal('atom', atom_node.node_info[:feed_type])
    assert_equal('rss', rss_node.node_info[:feed_type])

    assert_raises(Webgen::NodeCreationError) do
      path = Webgen::Path.new('/test_feed_2') { StringIO.new("---\nunknow: yes") }
      @feed.create_nodes(path, 'unused')
    end
  end

  def test_content
    @website.ext.content_processor = Webgen::ContentProcessor.new
    @website.ext.content_processor.register('Erb')
    @website.ext.content_processor.register('Blocks')

    atom_node, rss_node = @feed.create_nodes(@path, Webgen::Page.from_data(@path.data).blocks)
    assert_equal("hallo\n", @feed.content(rss_node))
    assert(@feed.content(atom_node) =~ /Thomas Leitner/)
    assert(@feed.content(atom_node) =~ /RealContent/)
  end

  def test_feed_entries
    atom_node, rss_node = @feed.create_nodes(@path, Webgen::Page.from_data(@path.data).blocks)
    assert_equal([@nodes[:index_en], @nodes[:file2_en]], atom_node.feed_entries)
    assert_equal([@nodes[:index_en], @nodes[:file2_en]], rss_node.feed_entries)
  end

end
