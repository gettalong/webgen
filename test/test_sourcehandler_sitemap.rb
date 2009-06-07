# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/sourcehandler'
require 'stringio'

class TestSourceHandlerSitemap < Test::Unit::TestCase

  include Test::WebsiteHelper

  SITEMAP_CONTENT = <<EOF
---
site_url: http://example.com
default_change_freq: daily
EOF

  def setup
    super
    @nodes = create_sitemap_nodes
    @nodes.each {|k,v| v['modified_at'] = Time.now}
    @nodes[:file11_en]['priority'] = 0.9
    @nodes[:file11_en]['change_freq'] = 'hourly'
    @obj = Webgen::SourceHandler::Sitemap.new
    @path = path_with_meta_info('/test.sitemap', {}, @obj.class.name) {StringIO.new(SITEMAP_CONTENT)}
  end

  def test_create_node
    sitemap = @obj.create_node(@path)

    assert_not_nil(sitemap)
    assert_equal('/test.xml', sitemap.path)
    assert_equal('/test.xml', sitemap.alcn)

    assert_raise(RuntimeError) do
      @obj.create_node(path_with_meta_info('/test.sitemap', {}, @obj.class.name) {StringIO.new('')})
    end
  end

  def test_content
    sitemap = @obj.create_node(@path)
    content = sitemap.content
    assert_match(/<changefreq>daily<\/changefreq>/, content)
    assert_match(/<changefreq>hourly<\/changefreq>/, content)
    assert_match(/<priority>0.5<\/priority>/, content)
    assert_match(/<priority>0.9<\/priority>/, content)
  end

end
