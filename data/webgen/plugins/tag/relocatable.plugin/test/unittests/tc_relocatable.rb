require 'webgen/test'
require 'webgen/node'

class RelocatableTagTest < Webgen::PluginTestCase

  plugin_to_test 'Tag/Relocatable'

  def call( context )
    @plugin.process_tag( 'relocatable', '', context )
  end

  def test_process_tag
    root = @manager['Core/FileHandler'].instance_eval { build_tree }

    node = root.resolve_node( 'file.html' )
    context = Context.new( {}, [node] )

    # basic node resolving
    @plugin.set_params( 'path' => 'dir/file.html', 'resolveFragment' => false )
    assert_equal( 'dir/file.html', call( context ) )
    @plugin.set_params( 'path' => 'dir/file.html', 'resolveFragment' => true )
    assert_equal( 'dir/file.html', call( context ) )

    @plugin.set_params( 'path' => 'file.html#hallo', 'resolveFragment' => false )
    assert_equal( 'file.html#hallo', call( context ) )
    @plugin.set_params( 'path' => 'file.html#hallo', 'resolveFragment' => true )
    assert_equal( '', call( context ) )

#TODO decomment after fragment nodes work
#    @plugin.set_params( 'path' => 'file_fragment.html#test', 'resolveFragment' => false )
#    assert_equal( 'file_fragment.html#test', call( context ) )
#    @plugin.set_params( 'path' => 'file_fragment.html#test', 'resolveFragment' => true )
#    assert_equal( 'file_fragment.html#test', call( context ) )


    # absolute paths
    @plugin.set_params( 'path' => 'http://test.com', 'resolveFragment' => false )
    assert_equal( 'http://test.com', call( context ) )
    @plugin.set_params( 'path' => 'http://test.com', 'resolveFragment' => true )
    assert_equal( 'http://test.com', call( context ) )


    # directory paths
    @plugin.set_params( 'path' => 'dir', 'resolveFragment' => true )
    assert_equal( 'dir/', call( context ) )

    @plugin.set_params( 'path' => 'dir2', 'resolveFragment' => true )
    assert_equal( 'dir2/index.html', call( context ) )

    # invalid paths
    @plugin.set_params( 'path' => ':/asdf=-)', 'resolveFragment' => true )
    assert_equal( '', call( context ) )
  end

end
