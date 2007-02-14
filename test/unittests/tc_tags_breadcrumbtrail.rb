require 'webgen/test'
require 'webgen/node'

class BreadcrumbTrailTagTest < Webgen::TagTestCase

  plugin_files [
    'webgen/plugins/tags/breadcrumbtrail.rb',
    'webgen/plugins/filehandlers/directory.rb',
    'webgen/plugins/filehandlers/page.rb',
  ]
  plugin_to_test 'Tag/BreadcrumbTrail'


  def test_process_tag
    root = @manager['Core/FileHandler'].instance_eval { build_tree }
    node = root.resolve_node( 'dir1/dir11/file111.en.page' )
    indexNode = root.resolve_node( 'dir1/dir11/index.en.page' )

    set_config( 'separator' => ' / ', 'omitLast' => false, 'omitIndexFile' => false )
    assert_equal( '<a href="../../index.html"></a> / <a href="../">Dir1</a> / <a href="index.html">Dir11</a> / <span>File111</span>',
                  @plugin.process_tag( 'breadcrumbTrail', [node] ) )
    set_config( 'separator' => ' / ', 'omitLast' => false, 'omitIndexFile' => true )
    assert_equal( '<a href="../../index.html"></a> / <a href="../">Dir1</a> / <a href="index.html">Dir11</a> / <span>File111</span>',
                  @plugin.process_tag( 'breadcrumbTrail', [node] ) )
    set_config( 'separator' => ' / ', 'omitLast' => true, 'omitIndexFile' => true )
    assert_equal( '<a href="../../index.html"></a> / <a href="../">Dir1</a> / <a href="index.html">Dir11</a> / ',
                  @plugin.process_tag( 'breadcrumbTrail', [node] ) )
    set_config( 'separator' => ' / ', 'omitLast' => true, 'omitIndexFile' => false )
    assert_equal( '<a href="../../index.html"></a> / <a href="../">Dir1</a> / <a href="index.html">Dir11</a> / ',
                  @plugin.process_tag( 'breadcrumbTrail', [node] ) )


    set_config( 'separator' => ' / ', 'omitLast' => false, 'omitIndexFile' => false )
    assert_equal( '<a href="../../index.html"></a> / <a href="../">Dir1</a> / <span>Dir11</span> / <span>Index</span>',
                  @plugin.process_tag( 'breadcrumbTrail', [indexNode] ) )
    set_config( 'separator' => ' / ', 'omitLast' => false, 'omitIndexFile' => true )
    assert_equal( '<a href="../../index.html"></a> / <a href="../">Dir1</a> / <span>Dir11</span>',
                  @plugin.process_tag( 'breadcrumbTrail', [indexNode] ) )
    set_config( 'separator' => ' / ', 'omitLast' => true, 'omitIndexFile' => true )
    assert_equal( '<a href="../../index.html"></a> / <a href="../">Dir1</a> / <span>Dir11</span>',
                  @plugin.process_tag( 'breadcrumbTrail', [indexNode] ) )
    set_config( 'separator' => ' / ', 'omitLast' => true, 'omitIndexFile' => false )
    assert_equal( '<a href="../../index.html"></a> / <a href="../">Dir1</a> / <span>Dir11</span> / ',
                  @plugin.process_tag( 'breadcrumbTrail', [indexNode] ) )

    indexNode['omitIndexFileInBreadcrumbTrail'] = false
    set_config( 'separator' => ' / ', 'omitLast' => false, 'omitIndexFile' => true )
    assert_equal( '<a href="../../index.html"></a> / <a href="../">Dir1</a> / <span>Dir11</span> / <span>Index</span>',
                  @plugin.process_tag( 'breadcrumbTrail', [indexNode] ) )
    indexNode['omitIndexFileInBreadcrumbTrail'] = true
    set_config( 'separator' => ' / ', 'omitLast' => false, 'omitIndexFile' => false )
    assert_equal( '<a href="../../index.html"></a> / <a href="../">Dir1</a> / <span>Dir11</span>',
                  @plugin.process_tag( 'breadcrumbTrail', [indexNode] ) )
  end

end
