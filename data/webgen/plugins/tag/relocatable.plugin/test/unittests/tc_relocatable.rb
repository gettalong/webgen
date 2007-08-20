require 'webgen/test'
require 'webgen/node'

class RelocatableTagTest < Webgen::TagTestCase

  plugin_to_test 'Tag/Relocatable'

  def test_process_tag
    root = @manager['Core/FileHandler'].instance_eval { build_tree }

    # basic node resolving
    node = root.resolve_node( 'file.html' )

    set_config( 'path' => 'dir/file.html', 'resolveFragment' => false )
    assert_equal( 'dir/file.html', @plugin.process_tag( 'relocatable', '', node, node ) )
    set_config( 'path' => 'dir/file.html', 'resolveFragment' => true )
    assert_equal( 'dir/file.html', @plugin.process_tag( 'relocatable', '', node, node ) )

    set_config( 'path' => 'file.html#hallo', 'resolveFragment' => false )
    assert_equal( 'file.html#hallo', @plugin.process_tag( 'relocatable', '', node, node ) )
    set_config( 'path' => 'file.html#hallo', 'resolveFragment' => true )
    assert_equal( '', @plugin.process_tag( 'relocatable', '', node, node ) )

#TODO decomment after fragment nodes work
#    set_config( 'path' => 'file_fragment.html#test', 'resolveFragment' => false )
#    assert_equal( 'file_fragment.html#test', @plugin.process_tag( 'relocatable', '', node, node ) )
#    set_config( 'path' => 'file_fragment.html#test', 'resolveFragment' => true )
#    assert_equal( 'file_fragment.html#test', @plugin.process_tag( 'relocatable', '', node, node ) )


    # absolute paths
    set_config( 'path' => 'http://test.com', 'resolveFragment' => false )
    assert_equal( 'http://test.com', @plugin.process_tag( 'relocatable', '', node, node ) )
    set_config( 'path' => 'http://test.com', 'resolveFragment' => true )
    assert_equal( 'http://test.com', @plugin.process_tag( 'relocatable', '', node, node ) )


    # directory paths
    set_config( 'path' => 'dir', 'resolveFragment' => true )
    assert_equal( 'dir/', @plugin.process_tag( 'relocatable', '', node, node ) )

    set_config( 'path' => 'dir2', 'resolveFragment' => true )
    assert_equal( 'dir2/index.html', @plugin.process_tag( 'relocatable', '', node, node ) )

    # invalid paths
    set_config( 'path' => ':/asdf=-)', 'resolveFragment' => true )
    assert_equal( '', @plugin.process_tag( 'relocatable', '', node, node ) )
  end

end
