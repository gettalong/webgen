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

  def call(context, separator, omit_last, omit_index_path)
    @obj.set_params({'tag.breadcrumbtrail.separator' => separator,
                      'tag.breadcrumbtrail.omit_last' => omit_last,
                      'tag.breadcrumbtrail.omit_index_path' => omit_index_path})
    result = @obj.call('breadcrumbTrail', '', context)
    @obj.set_params({})
    result
  end

  def test_call
    nodes = create_default_nodes
    context = Webgen::ContentProcessor::Context.new(:chain => [nodes[:file11_en]])

    assert_equal('<a href="../../index.html"></a> / <a href="../">Dir1</a> / <a href="index.html">Dir11</a> / <span>File111</span>',
                 call(context, ' / ', false, false))
    assert_equal(Set.new([nodes[:file11_en], nodes[:index_en], nodes[:index11_en], nodes[:dir1], nodes[:dir11], nodes[:root]].map {|n| n.absolute_lcn}),
                 nodes[:file11_en].node_info[:used_nodes])


    assert_equal('<a href="../../index.html"></a> / <a href="../">Dir1</a> / <a href="index.html">Dir11</a> / <span>File111</span>',
                 call(context, ' / ', false, true))
    assert_equal('<a href="../../index.html"></a> / <a href="../">Dir1</a> / <a href="index.html">Dir11</a> / ',
                 call(context, ' / ', true, true))
    assert_equal('<a href="../../index.html"></a> / <a href="../">Dir1</a> / <a href="index.html">Dir11</a> / ',
                 call(context, ' / ', true, false))


    context[:chain] = [nodes[:index11_en]]
    assert_equal('<a href="../../index.html"></a> / <a href="../">Dir1</a> / <span>Dir11</span> / <span>Index</span>',
                 call(context, ' / ', false, false))
    assert_equal('<a href="../../index.html"></a> / <a href="../">Dir1</a> / <span>Dir11</span>',
                 call(context, ' / ', false, true))
    assert_equal('<a href="../../index.html"></a> / <a href="../">Dir1</a> / <span>Dir11</span>',
                 call(context, ' / ', true, true))
    assert_equal('<a href="../../index.html"></a> / <a href="../">Dir1</a> / <span>Dir11</span> / ',
                 call(context, ' / ', true, false))

    assert_equal('<a href="../../index.html"></a> | <a href="../">Dir1</a> | <span>Dir11</span> | ',
                 call(context, ' | ', true, false))


    nodes[:index11_en]['omit_index_path'] = false
    assert_equal('<a href="../../index.html"></a> / <a href="../">Dir1</a> / <span>Dir11</span> / <span>Index</span>',
                 call(context, ' / ', false, true))
    nodes[:index11_en]['omit_index_path'] = true
    assert_equal('<a href="../../index.html"></a> / <a href="../">Dir1</a> / <span>Dir11</span>',
                 call(context, ' / ', false, false))
  end

end
