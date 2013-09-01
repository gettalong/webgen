# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/content_processor'
require 'webgen/tag/breadcrumb_trail'

class TestTagBreadcrumbTrail < Minitest::Test

  include Webgen::TestHelper

  def test_call
    context = setup_context
    @website.ext.content_processor = Webgen::ContentProcessor.new
    @website.ext.content_processor.register('Blocks')
    @website.ext.content_processor.register('Ruby')
    @obj = Webgen::Tag::BreadcrumbTrail

    root = Webgen::Node.new(@website.tree.dummy_root, '/', '/', {'proxy_path' => 'index.html'})
    dir1 = Webgen::Node.new(root, 'dir1/', '/dir1/', {'title' => 'Dir1'})
    dir11 = Webgen::Node.new(dir1, 'dir11/', '/dir1/dir11/', {'proxy_path' => 'index.html'})
    index11_en = Webgen::Node.new(dir11, 'index.html', '/dir1/dir11/index.html',
                                  {'lang' => 'en', 'routed_title' => 'Dir11', 'title' => 'Index'})
    file11_en = Webgen::Node.new(dir11, 'file111.html', '/dir1/dir11/file111.html',
                                 {'lang' => 'en', 'title' => 'File111'})
    index_en = Webgen::Node.new(root, 'index.html', '/index.html', {'lang' => 'en'})
    setup_tag_template(root)

    context[:chain] = [file11_en]
    assert_tag_result(context, '<a href="../../index.html" hreflang="en"></a> / <a href="../">Dir1</a> / <a href="index.html" hreflang="en">Dir11</a> / <a href="file111.html" hreflang="en">File111</a>',
                      false, 0, -1)
    assert_tag_result(context, '<a href="../../index.html" hreflang="en"></a> / <a href="../">Dir1</a> / <a href="index.html" hreflang="en">Dir11</a> / <a href="file111.html" hreflang="en">File111</a>',
                      true, 0, -1)
    assert_tag_result(context, '<a href="../">Dir1</a> / <a href="index.html" hreflang="en">Dir11</a>',
                      true, 1, -2)
    assert_tag_result(context, '<a href="../">Dir1</a> / <a href="index.html" hreflang="en">Dir11</a>',
                      false, 1, -2)


    context[:chain] = [index11_en]
    assert_tag_result(context, '<a href="../../index.html" hreflang="en"></a> / <a href="../">Dir1</a> / <a href="index.html" hreflang="en">Dir11</a> / <a href="index.html" hreflang="en">Index</a>',
                      false, 0, -1)
    assert_tag_result(context, '<a href="../../index.html" hreflang="en"></a> / <a href="../">Dir1</a> / <a href="index.html" hreflang="en">Dir11</a>',
                      true, 0, -1)
    assert_tag_result(context, '<a href="../../index.html" hreflang="en"></a> / <a href="../">Dir1</a> / <a href="index.html" hreflang="en">Dir11</a>',
                      false, 0, -2)
    assert_tag_result(context, '<a href="../../index.html" hreflang="en"></a> / <a href="../">Dir1</a>',
                      true, 0, -2)

    index11_en.meta_info['omit_dir_index'] = false
    assert_tag_result(context, '<a href="../../index.html" hreflang="en"></a> / <a href="../">Dir1</a> / <a href="index.html" hreflang="en">Dir11</a> / <a href="index.html" hreflang="en">Index</a>',
                      true, 0, -1)
    index11_en.meta_info['omit_dir_index'] = true
    assert_tag_result(context, '<a href="../../index.html" hreflang="en"></a> / <a href="../">Dir1</a> / <a href="index.html" hreflang="en">Dir11</a>',
                      false, 0, -1)
  end

  def assert_tag_result(context, result, omit_dir_index, start_level, end_level)
    context[:config] = {'tag.breadcrumb_trail.omit_dir_index' => omit_dir_index,
      'tag.breadcrumb_trail.start_level' => start_level,
      'tag.breadcrumb_trail.end_level' => end_level,
      'tag.breadcrumb_trail.template' => '/tag.template',
      'tag.breadcrumb_trail.separator' => ' / '}
    assert_equal(result, Webgen::Tag::BreadcrumbTrail.call('breadcrumb_trail', '', context))
  end

end
