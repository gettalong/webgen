require 'webgen/test'
require 'webgen/node'

class BreadcrumbTrailTagTest < Webgen::PluginTestCase

  plugin_to_test 'Tag/BreadcrumbTrail'

  def call( context, chain )
    context.chain = chain
    @plugin.process_tag( 'breadcrumbTrail', '', context )
  end

  def test_process_tag
    root = @manager['Core/FileHandler'].instance_eval { build_tree }
    root['title'] = ''
    node = root.resolve_node( 'dir1/dir11/file111.en.html' )
    indexNode = root.resolve_node( 'dir1/dir11/index.en.html' )
    context = Context.new( {}, [node] )

    @plugin.set_params( 'separator' => ' / ', 'omitLast' => false, 'omitIndexFile' => false )
    assert_equal( '<a href="../../index.html"></a> / <a href="../">Dir1</a> / <a href="index.html">Dir11</a> / <span>File111</span>',
                  call( context, [node] ) )
    assert_equal( [
                   root.resolve_node( '/dir1/dir11/file111.en.html' ),
                   root.resolve_node( '/dir1/dir11/' ),
                   root.resolve_node( '/dir1/' ),
                   root.resolve_node( '/'),
                  ].collect {|n| n.absolute_lcn}, context.cache_info[@plugin.plugin_name] )



    @plugin.set_params( 'separator' => ' / ', 'omitLast' => false, 'omitIndexFile' => true )
    assert_equal( '<a href="../../index.html"></a> / <a href="../">Dir1</a> / <a href="index.html">Dir11</a> / <span>File111</span>',
                  call( context, [node] ) )
    @plugin.set_params( 'separator' => ' / ', 'omitLast' => true, 'omitIndexFile' => true )
    assert_equal( '<a href="../../index.html"></a> / <a href="../">Dir1</a> / <a href="index.html">Dir11</a> / ',
                  call( context, [node] ) )
    @plugin.set_params( 'separator' => ' / ', 'omitLast' => true, 'omitIndexFile' => false )
    assert_equal( '<a href="../../index.html"></a> / <a href="../">Dir1</a> / <a href="index.html">Dir11</a> / ',
                  call( context, [node] ) )


    @plugin.set_params( 'separator' => ' / ', 'omitLast' => false, 'omitIndexFile' => false )
    assert_equal( '<a href="../../index.html"></a> / <a href="../">Dir1</a> / <span>Dir11</span> / <span>Index</span>',
                  call( context, [indexNode] ) )
    @plugin.set_params( 'separator' => ' / ', 'omitLast' => false, 'omitIndexFile' => true )
    assert_equal( '<a href="../../index.html"></a> / <a href="../">Dir1</a> / <span>Dir11</span>',
                  call( context, [indexNode] ) )
    @plugin.set_params( 'separator' => ' / ', 'omitLast' => true, 'omitIndexFile' => true )
    assert_equal( '<a href="../../index.html"></a> / <a href="../">Dir1</a> / <span>Dir11</span>',
                  call( context, [indexNode] ) )
    @plugin.set_params( 'separator' => ' / ', 'omitLast' => true, 'omitIndexFile' => false )
    assert_equal( '<a href="../../index.html"></a> / <a href="../">Dir1</a> / <span>Dir11</span> / ',
                  call( context, [indexNode] ) )

    indexNode['omitIndexFileInBreadcrumbTrail'] = false
    @plugin.set_params( 'separator' => ' / ', 'omitLast' => false, 'omitIndexFile' => true )
    assert_equal( '<a href="../../index.html"></a> / <a href="../">Dir1</a> / <span>Dir11</span> / <span>Index</span>',
                  call( context, [indexNode] ) )
    indexNode['omitIndexFileInBreadcrumbTrail'] = true
    @plugin.set_params( 'separator' => ' / ', 'omitLast' => false, 'omitIndexFile' => false )
    assert_equal( '<a href="../../index.html"></a> / <a href="../">Dir1</a> / <span>Dir11</span>',
                  call( context, [indexNode] ) )
  end

end
