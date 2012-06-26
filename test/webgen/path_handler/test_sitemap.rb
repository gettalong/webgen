# -*- encoding: utf-8 -*-

require 'helper'
require 'ostruct'
require 'logger'
require 'stringio'
require 'webgen/path_handler/sitemap'
require 'webgen/content_processor'
require 'webgen/node_finder'
require 'webgen/tree'
require 'webgen/node'
require 'webgen/path'
require 'webgen/website'

class TestPathHandlerSitemap < MiniTest::Unit::TestCase

  SITEMAP_CONTENT = <<EOF
---
site_url: http://example.com
default_change_freq: daily
default_priority: 0.5
entries:
  :alcn: /**/*.html
EOF

  SITEMAP_CONTENT_TEMPLATE = <<EOF
---
site_url: http://example.com
default_change_freq: daily
default_priority: 0.5
entries:
  :alcn: /**/*.html
--- name:sitemap pipeline:erb
Yeah <%= context.node['title'] %>
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

    @sitemap = Webgen::PathHandler::Sitemap.new(@website)

    @nodes = Test.create_default_nodes(@website.tree)
    @nodes.each {|k,v| v.meta_info['modified_at'] = Time.now}
    @nodes[:somename_en].meta_info['priority'] = 0.9
    @nodes[:somename_en].meta_info['change_freq'] = 'hourly'

    @template = Test::RenderNode.new(@nodes[:root], 'sitemap.template', '/templates/sitemap.template')
    template_data = File.read(File.join(Webgen.data_dir, 'passive_sources', 'templates', 'sitemap.template'))
    template_page = Webgen::Page.from_data(template_data)
    @template.node_info[:blocks] = template_page.blocks
    @template.meta_info.update(template_page.meta_info)

    @path = Webgen::Path.new('/test.sitemap', 'dest_path' => '<parent><basename><ext>') { StringIO.new(SITEMAP_CONTENT) }
    @path.meta_info.update(Webgen::Page.from_data(SITEMAP_CONTENT).meta_info)
  end

  def test_create_node
    node = @sitemap.create_nodes(@path, Webgen::Page.from_data(@path.data).blocks)

    refute_nil(node)
    assert_equal('/test.xml', node.dest_path)
    assert_equal('/test.xml', node.alcn)

    assert_raises(Webgen::NodeCreationError) do
      path = Webgen::Path.new('/test_feed_2') { StringIO.new("---\nunknow: yes") }
      @sitemap.create_nodes(path, 'unused')
    end
  end

  def test_content
    @website.ext.content_processor = Webgen::ContentProcessor.new
    @website.ext.content_processor.register('Erb')
    @website.ext.content_processor.register('Blocks')

    content = @sitemap.create_nodes(@path, Webgen::Page.from_data(@path.data).blocks).content
    assert_match(/<changefreq>daily<\/changefreq>/, content)
    assert_match(/<changefreq>hourly<\/changefreq>/, content)
    assert_match(/<priority>0.5<\/priority>/, content)
    assert_match(/<priority>0.9<\/priority>/, content)
  end

  def test_content_with_template
    @website.ext.content_processor = Webgen::ContentProcessor.new
    @website.ext.content_processor.register('Erb')
    @website.ext.content_processor.register('Blocks')

    path = Webgen::Path.new('/test.sitemap', 'dest_path' => '<parent><basename><ext>') { StringIO.new(SITEMAP_CONTENT_TEMPLATE) }
    path.meta_info.update(Webgen::Page.from_data(SITEMAP_CONTENT_TEMPLATE).meta_info)
    node = @sitemap.create_nodes(path, Webgen::Page.from_data(path.data).blocks)

    refute_nil(node)
    node.meta_info['title'] = 'testit'
    assert_equal("Yeah testit\n", node.content)
  end

  def test_sitemap_entries
    node = @sitemap.create_nodes(@path, Webgen::Page.from_data(@path.data).blocks)
    assert_equal([:somename_en, :somename_de, :other, :other_en, :dir_file,
                  :dir2_index_en, :dir2_index_de].map {|n| @nodes[n]}, node.sitemap_entries)
  end

end
