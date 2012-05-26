# -*- encoding: utf-8 -*-

require 'helper'
require 'webgen/website'
require 'webgen/content_processor'
require 'webgen/tag/breadcrumb_trail'

class TestTagBreadcrumbTrail < MiniTest::Unit::TestCase

  def test_call
    @obj = Webgen::Tag::BreadcrumbTrail
    website, context = Test.setup_tag_test
    website.expect(:config, {'website.link_to_current_page' => false})
    website.expect(:tree, Webgen::Tree.new(website))
    website.expect(:logger, Logger.new(StringIO.new))
    website.ext.item_tracker = MiniTest::Mock.new
    def (website.ext.item_tracker).add(*args); end
    website.ext.content_processor = Webgen::ContentProcessor.new
    website.ext.content_processor.register('Blocks')
    website.ext.content_processor.register('Ruby')

    root = Webgen::Node.new(website.tree.dummy_root, '/', '/', {'proxy_path' => 'index.html'})
    dir1 = Webgen::Node.new(root, 'dir1/', '/dir1/', {'title' => 'Dir1'})
    dir11 = Webgen::Node.new(dir1, 'dir11/', '/dir1/dir11/', {'proxy_path' => 'index.html'})
    index11_en = Webgen::Node.new(dir11, 'index.html', '/dir1/dir11/index.html',
                                  {'lang' => 'en', 'routed_title' => 'Dir11', 'title' => 'Index'})
    file11_en = Webgen::Node.new(dir11, 'file111.html', '/dir1/dir11/file111.html',
                                 {'lang' => 'en', 'title' => 'File111'})
    index_en = Webgen::Node.new(root, 'index.html', '/index.html', {'lang' => 'en'})
    template = Test.setup_tag_template(root)

    context[:chain] = [file11_en]
    assert_tag_result(context, '<a href="../../index.html"></a> / <a href="../">Dir1</a> / <a href="index.html">Dir11</a> / <span>File111</span>',
                      false, 0, -1)
    assert_tag_result(context, '<a href="../../index.html"></a> / <a href="../">Dir1</a> / <a href="index.html">Dir11</a> / <span>File111</span>',
                      true, 0, -1)
    assert_tag_result(context, '<a href="../">Dir1</a> / <a href="index.html">Dir11</a>',
                      true, 1, -2)
    assert_tag_result(context, '<a href="../">Dir1</a> / <a href="index.html">Dir11</a>',
                      false, 1, -2)


    context[:chain] = [index11_en]
    assert_tag_result(context, '<a href="../../index.html"></a> / <a href="../">Dir1</a> / <span>Dir11</span> / <span>Index</span>',
                      false, 0, -1)
    assert_tag_result(context, '<a href="../../index.html"></a> / <a href="../">Dir1</a> / <span>Dir11</span>',
                      true, 0, -1)
    assert_tag_result(context, '<a href="../../index.html"></a> / <a href="../">Dir1</a> / <span>Dir11</span>',
                      false, 0, -2)
    assert_tag_result(context, '<a href="../../index.html"></a> / <a href="../">Dir1</a>',
                      true, 0, -2)

    index11_en.meta_info['omit_dir_index'] = false
    assert_tag_result(context, '<a href="../../index.html"></a> / <a href="../">Dir1</a> / <span>Dir11</span> / <span>Index</span>',
                      true, 0, -1)
    index11_en.meta_info['omit_dir_index'] = true
    assert_tag_result(context, '<a href="../../index.html"></a> / <a href="../">Dir1</a> / <span>Dir11</span>',
                      false, 0, -1)
  end

  def assert_tag_result(context, result, omit_dir_index, start_level, end_level)
    context[:config] = {'tag.breadcrumb_trail.omit_dir_index' => omit_dir_index,
      'tag.breadcrumb_trail.start_level' => start_level,
      'tag.breadcrumb_trail.end_level' => end_level,
      'tag.breadcrumb_trail.template' => '/tag.template'}
    assert_equal(result, Webgen::Tag::BreadcrumbTrail.call('breadcrumb_trail', '', context))
  end

end
