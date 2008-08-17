require 'test/unit'
require 'helper'
require 'webgen/tree'
require 'webgen/contentprocessor'
require 'webgen/tag'

class TestTagBreadcrumbTrail < Test::Unit::TestCase

  include Test::WebsiteHelper

  def setup
    super
    @obj = Webgen::Tag::BreadcrumbTrail.new
  end

  def create_default_nodes
    {
      :root => root = Webgen::Node.new(Webgen::Tree.new.dummy_root, '/', '/', {'index_path' => 'index.html'}),
      :dir1 => dir1 = Webgen::Node.new(root, '/dir1/', 'dir1/', {'title' => 'Dir1'}),
      :dir11 => dir11 = Webgen::Node.new(dir1, '/dir1/dir11/', 'dir11/', {'index_path' => 'index.html'}),
      :index11_en => Webgen::Node.new(dir11, '/dir1/dir11/index.html', 'index.html',
                                      {'lang' => 'en', 'routed_title' => 'Dir11', 'title' => 'Index'}),
      :file11_en => Webgen::Node.new(dir11, '/dir1/dir11/file111.html', 'file111.html',
                                     {'lang' => 'en', 'title' => 'File111'}),
      :index_en => Webgen::Node.new(root, '/index.html', 'index.html', {'lang' => 'en'}),
    }
  end

  def call(context, separator, omit_index_path, start_level, end_level)
    @obj.set_params({'tag.breadcrumbtrail.separator' => separator,
                      'tag.breadcrumbtrail.omit_index_path' => omit_index_path,
                      'tag.breadcrumbtrail.start_level' => start_level,
                      'tag.breadcrumbtrail.end_level' => end_level})
    result = @obj.call('breadcrumbTrail', '', context)
    @obj.set_params({})
    result
  end

  def test_call
    nodes = create_default_nodes
    context = Webgen::ContentProcessor::Context.new(:chain => [nodes[:file11_en]])

    assert_equal('<a href="../../index.html"></a> / <a href="../">Dir1</a> / <a href="index.html">Dir11</a> / <span>File111</span>',
                 call(context, ' / ', false, 0, -1))
    assert_equal('<a href="../../index.html"></a> / <a href="../">Dir1</a> / <a href="index.html">Dir11</a> / <span>File111</span>',
                 call(context, ' / ', true, 0, -1))
    assert_equal('<a href="../">Dir1</a> / <a href="index.html">Dir11</a>',
                 call(context, ' / ', true, 1, -2))
    assert_equal('<a href="../">Dir1</a> / <a href="index.html">Dir11</a>',
                 call(context, ' / ', false, 1, -2))


    context[:chain] = [nodes[:index11_en]]
    assert_equal('<a href="../../index.html"></a> / <a href="../">Dir1</a> / <span>Dir11</span> / <span>Index</span>',
                 call(context, ' / ', false, 0, -1))
    assert_equal('<a href="../../index.html"></a> / <a href="../">Dir1</a> / <span>Dir11</span>',
                 call(context, ' / ', true, 0, -1))
    assert_equal('<a href="../../index.html"></a> / <a href="../">Dir1</a> / <span>Dir11</span>',
                 call(context, ' / ', false, 0, -2))
    assert_equal('<a href="../../index.html"></a> / <a href="../">Dir1</a>',
                 call(context, ' / ', true, 0, -2))

    assert_equal('<a href="../../index.html"></a> | <a href="../">Dir1</a> | <span>Dir11</span> | <span>Index</span>',
                 call(context, ' | ', false, 0, -1))


    nodes[:index11_en]['omit_index_path'] = false
    assert_equal('<a href="../../index.html"></a> / <a href="../">Dir1</a> / <span>Dir11</span> / <span>Index</span>',
                 call(context, ' / ', true, 0, -1))
    nodes[:index11_en]['omit_index_path'] = true
    assert_equal('<a href="../../index.html"></a> / <a href="../">Dir1</a> / <span>Dir11</span>',
                 call(context, ' / ', false, 0, -1))
  end

  def test_node_changed
    nodes = create_default_nodes
    context = Webgen::ContentProcessor::Context.new(:chain => [nodes[:file11_en]])
    call(context, ' / ', false, 0, -1)

    nodes[:file11_en].dirty = false
    @website.blackboard.dispatch_msg(:node_changed?, nodes[:file11_en])
    assert(!nodes[:file11_en].dirty)

    nodes[:index11_en].dirty_meta_info = true
    @website.blackboard.dispatch_msg(:node_changed?, nodes[:file11_en])
    assert(nodes[:file11_en].dirty)
  end

end
