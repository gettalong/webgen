require 'webgen/test'
require 'webgen/node'

class RelocatableTagTest < Webgen::TagTestCase

  plugin_files [
    'webgen/plugins/tags/relocatable.rb',
    'webgen/plugins/filehandlers/directory.rb',
    'webgen/plugins/filehandlers/page.rb',
  ]
  plugin_to_test 'Tags::RelocatableTag'


  def test_process_tag
    root = @manager['FileHandlers::FileHandler'].instance_eval { build_tree }

    # basic node resolving
    node = root.resolve_node( 'file1.page' )

    set_config( 'path' => 'dir1/file11.page', 'resolveFragment' => false )
    assert_equal( 'dir1/file11.html', @plugin.process_tag( 'relocatable', [node] ) )
    set_config( 'path' => 'dir1/file11.html', 'resolveFragment' => true )
    assert_equal( 'dir1/file11.html', @plugin.process_tag( 'relocatable', [node] ) )

    set_config( 'path' => 'file1.html#hallo', 'resolveFragment' => false )
    assert_equal( 'file1.html#hallo', @plugin.process_tag( 'relocatable', [node] ) )
    set_config( 'path' => 'file1.html#hallo', 'resolveFragment' => true )
    assert_equal( '', @plugin.process_tag( 'relocatable', [node] ) )

    set_config( 'path' => 'file1.html#test', 'resolveFragment' => false )
    assert_equal( 'file1.html#test', @plugin.process_tag( 'relocatable', [node] ) )
    set_config( 'path' => 'file1.html#test', 'resolveFragment' => true )
    assert_equal( 'file1.html#test', @plugin.process_tag( 'relocatable', [node] ) )

    node = root.resolve_node( 'index.en.page' )

    set_config( 'path' => 'index.page#test', 'resolveFragment' => true )
    assert_equal( '', @plugin.process_tag( 'relocatable', [node] ) )
    set_config( 'path' => 'index.de.page#test', 'resolveFragment' => true )
    assert_equal( 'index.de.html#test', @plugin.process_tag( 'relocatable', [node] ) )

    set_config( 'path' => 'file2.page', 'resolveFragment' => true )
    assert_equal( '', @plugin.process_tag( 'relocatable', [node] ) )
    set_config( 'path' => 'file2.de.page', 'resolveFragment' => true )
    assert_equal( 'file2.de.html', @plugin.process_tag( 'relocatable', [node] ) )

    # absolute paths
    set_config( 'path' => 'http://test.com', 'resolveFragment' => false )
    assert_equal( 'http://test.com', @plugin.process_tag( 'relocatable', [node] ) )
    set_config( 'path' => 'http://test.com', 'resolveFragment' => true )
    assert_equal( 'http://test.com', @plugin.process_tag( 'relocatable', [node] ) )


    # directory paths
    set_config( 'path' => 'dir1', 'resolveFragment' => true )
    assert_equal( 'dir1/', @plugin.process_tag( 'relocatable', [node] ) )

    set_config( 'path' => 'dir1/dir11', 'resolveFragment' => true )
    assert_equal( 'dir1/dir11/index.html', @plugin.process_tag( 'relocatable', [node] ) )

    # invalid paths
    set_config( 'path' => ':/asdf=-)', 'resolveFragment' => true )
    assert_equal( '', @plugin.process_tag( 'relocatable', [node] ) )
  end

end
