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

  def create_default_nodes
    {
      :root => root = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/', {'index_path' => 'index.html'}),
      :dir1 => dir1 = Webgen::Node.new(root, '/dir1/', 'dir1/'),
      :file11_en => file11 = Webgen::Node.new(dir1, '/dir1/file11.en.html', 'file11.html', {'lang' => 'en', 'in_menu' => true, 'kind' => 'page'}),
      :file11_en_f1 => file11_f1 = Webgen::Node.new(file11, '/dir1/file11.en.html#f1', '#f1', {'in_menu' => true}),
      :dir2 => dir2 = Webgen::Node.new(root, '/dir2/', 'dir2/'),
      :file21_en => Webgen::Node.new(dir2, '/dir2/file21.en.html', 'file21.html', {'lang' => 'en', 'in_menu' => true, 'kind' => 'other'}),
      :file1_de => Webgen::Node.new(root, '/file1.de.html', 'file1.html', {'lang' => 'de', 'in_menu' => true, 'kind' => 'page'}),
      :index_en => Webgen::Node.new(root, '/index.en.html', 'index.html', {'lang' => 'en', 'kind' => 'page'}),
    }
  end

  def call(context, honor_in_menu, any_lang, used_kinds)
    @obj.set_params({'tag.sitemap.honor_in_menu' => honor_in_menu,
                      'tag.sitemap.any_lang' => any_lang,
                      'tag.sitemap.used_kinds' => used_kinds})
    result = @obj.call('sitemap', '', context)
    @obj.set_params({})
    result
  end

  def test_call
    nodes = create_default_nodes
    context = Webgen::ContentProcessor::Context.new(:chain => [nodes[:file11_en]])

    assert_equal("<ul><li><a href=\"./\"></a>" +
                 "<ul><li><span></span></li></ul></li>" +
                 "<li><a href=\"../index.en.html\"></a></li></ul>",
                 call(context, false, false, ['page']))
    assert_equal("<ul><li><a href=\"./\"></a>" +
                 "<ul><li><span></span></li></ul></li></ul>",
                 call(context, true, false, ['page']))
    assert_equal("<ul><li><a href=\"./\"></a>" +
                 "<ul><li><span></span></li></ul></li>" +
                 "<li><a href=\"../dir2/\"></a>" +
                 "<ul><li><a href=\"../dir2/file21.en.html\"></a></li></ul></li>"+
                 "<li><a href=\"../index.en.html\"></a></li></ul>",
                 call(context, false, false, ['page', 'other']))
    assert_equal("<ul><li><a href=\"./\"></a>" +
                 "<ul><li><span></span>"+
                 "<ul><li><a href=\"#f1\"></a></li></ul></li></ul></li>" +
                 "<li><a href=\"../dir2/\"></a>" +
                 "<ul><li><a href=\"../dir2/file21.en.html\"></a></li></ul></li>"+
                 "<li><a href=\"../index.en.html\"></a></li></ul>",
                 call(context, false, false, []))
    assert_equal("",
                 call(context, false, false, ['noone']))

    context[:chain] = [nodes[:file1_de]]
    assert_equal("<ul><li><span></span></li></ul>",
                 call(context, false, false, ['page']))
    assert_equal("<ul><li><a href=\"dir1/\"></a>" +
                 "<ul><li><a href=\"dir1/file11.en.html\"></a></li></ul></li>" +
                 "<li><span></span></li><li><a href=\"index.en.html\"></a></li></ul>",
                 call(context, false, true, ['page']))


    nodes[:file11_en].dirty = false
    @website.blackboard.dispatch_msg(:node_changed?, nodes[:file11_en])
    assert(!nodes[:file11_en].dirty)

    nodes[:file11_en].dirty_meta_info = true
    @website.blackboard.dispatch_msg(:node_changed?, nodes[:file11_en])
    assert(nodes[:file11_en].dirty)
  end

end
