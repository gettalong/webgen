# -*- encoding: utf-8 -*-

require 'test/unit'
require 'helper'
require 'webgen/tree'
require 'webgen/contentprocessor'
require 'webgen/tag'

class TestTagSitemap < Test::Unit::TestCase

  include Test::WebsiteHelper

  def setup
    super
    @obj = Webgen::Tag::Sitemap.new
  end

  def call(context, honor_in_menu, any_lang, used_kinds)
    @obj.set_params({'common.sitemap.honor_in_menu' => honor_in_menu,
                      'common.sitemap.any_lang' => any_lang,
                      'common.sitemap.used_kinds' => used_kinds})
    result = @obj.call('sitemap', '', context)
    @obj.set_params({})
    result
  end

  def test_call
    nodes = create_sitemap_nodes
    context = Webgen::ContentProcessor::Context.new(:chain => [nodes[:file11_en]])

    assert_equal("<ul><li><a href=\"./\"></a>" +
                 "<ul><li><span></span>"+
                 "<ul><li><a href=\"#f1\"></a></li></ul></li></ul></li>" +
                 "<li><a href=\"../dir2/\"></a>" +
                 "<ul><li><a href=\"../dir2/file21.en.html\"></a></li></ul></li>"+
                 "<li><a href=\"../index.en.html\"></a></li>" +
                 "<li><a href=\"../dir3/index.en.html\"></a></li></ul>",
                 call(context, false, false, []))
    assert_equal("",
                 call(context, false, false, ['noone']))
  end

  def test_tag_config_base
    assert_equal('common.sitemap', @obj.send(:tag_config_base))
  end

end
