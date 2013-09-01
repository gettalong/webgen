# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/path_handler/sitemap'
require 'webgen/content_processor'
require 'webgen/node_finder'
require 'webgen/path'

class TestPathHandlerSitemap < Minitest::Test

  include Webgen::TestHelper

  SITEMAP_CONTENT = <<EOF
---
default_change_freq: daily
default_priority: 0.5
entries:
  :alcn: /**/*.html
EOF

  SITEMAP_CONTENT_TEMPLATE = <<EOF
---
default_change_freq: daily
default_priority: 0.5
entries:
  :alcn: /**/*.html
--- name:sitemap pipeline:erb
Yeah <%= context.node['title'] %>
EOF

  def setup
    setup_website('website.lang' => 'en', 'website.base_url' => 'http://example.com')
    @website.ext.node_finder = Webgen::NodeFinder.new(@website)

    @sitemap = Webgen::PathHandler::Sitemap.new(@website)

    setup_default_nodes(@website.tree, Webgen::PathHandler::Base::Node)
    @website.tree.node_access[:alcn].each_value {|n| n.meta_info['modified_at'] = Time.now}
    @website.tree['/file.en.html'].meta_info['priority'] = 0.9
    @website.tree['/file.en.html'].meta_info['change_freq'] = 'hourly'

    template_data = File.read(File.join(Webgen::Utils.data_dir, 'passive_sources', 'templates', 'sitemap.template'))
    RenderNode.new(template_data, @website.tree.root, 'sitemap.template', '/templates/sitemap.template')

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

    assert_equal("Yeah Test\n", node.content)
  end

  def test_sitemap_entries
    node = @sitemap.create_nodes(@path, Webgen::Page.from_data(@path.data).blocks)
    assert_equal(%w[/file.en.html /file.de.html /other.html /other.en.html /german.de.html
                    /dir/subfile.html /dir/dir/file.html /dir2/index.en.html
                    /dir2/index.de.html].map {|n| @website.tree[n]}, node.sitemap_entries)
  end

end
