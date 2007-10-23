require 'webgen/test'
require 'webgen/node'
require 'webgen/config'

class CopyHandlerTest < Webgen::PluginTestCase

  plugin_to_test 'File/CopyHandler'

  def test_create_node
    root = @manager['Core/FileHandler'].instance_eval { create_root_node }

    # normal file
    src_file = File.join( @plugin.param( 'srcDir', 'Core/Configuration' ), 'normal.jpg' )
    file_info = @manager::Core::FileHandler::FileInfo.new( src_file )
    file_info.meta_info.update({'test'=>'hallo', 'title'=>'none'})
    file = @plugin.create_node( root, file_info )
    assert_equal( 'normal.jpg', file.path )
    assert_equal( 'none', file['title'] )
    assert_equal( 'hallo', file['test'] )
    assert_equal( src_file, file.node_info[:src] )
    assert_equal( @plugin, file.node_info[:processor] )
    assert_equal( nil, file.node_info[:preprocessor] )
    assert_same( file, @plugin.create_node( root, file_info ) )

    # ERB preprocessed file
    src_file = File.join( @plugin.param( 'srcDir', 'Core/Configuration' ), 'embedded.erb.html' )
    file_info = @manager::Core::FileHandler::FileInfo.new( src_file )
    file_info.meta_info.update({'hallo'=>'hallo', 'title'=>'title'})
    file = @plugin.create_node( root, file_info )
    assert_equal( 'embedded.html', file.path )
    assert_equal( 'title', file['title'] )
    assert_equal( 'hallo', file['hallo'] )
    assert_equal( src_file, file.node_info[:src] )
    assert_equal( @plugin, file.node_info[:processor] )
    assert_equal( 'erb', file.node_info[:preprocessor] )
    assert_same( file, @plugin.create_node( root, file_info ) )
  end

  def test_write_node
    root = @manager['Core/FileHandler'].instance_eval { create_root_node }

    check_write_node( root, 'normal.jpg' )

    file, write_info = check_write_node( root, 'embedded.erb.html' )
    assert_equal( "true", write_info[:data] )
  end

  def check_write_node( root, file )
    src_file = File.join( @plugin.param( 'srcDir', 'Core/Configuration' ), file )
    file_info = @manager::Core::FileHandler::FileInfo.new( src_file )
    file = @plugin.create_node( root, file_info )

    write_info = file.write_info
    if file.node_info[:preprocessor]
      assert( write_info.has_key?(:data) )
    else
      assert_equal( src_file, write_info[:src] )
    end
    [file, write_info]
  end

end

