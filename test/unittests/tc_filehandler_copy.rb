require 'webgen/test'

class FileCopyHandlerTest < Webgen::PluginTestCase

  plugin_files [
    'webgen/plugins/filehandlers/directory.rb',
    'webgen/plugins/filehandlers/copy.rb'
  ]
  plugin_to_test 'File/CopyHandler'

  def test_create_node
    root = @manager['Core/FileHandler'].instance_eval { create_root_node }

    # normal file
    src_file = File.join( @manager.param_for_plugin( 'Core/Configuration', 'srcDir' ), 'file1.page' )
    file = @plugin.create_node( src_file, root, {'test'=>'hallo', 'title'=>'none'} )
    assert_equal( 'file1.page', file.path )
    assert_equal( 'none', file['title'] )
    assert_equal( 'hallo', file['test'] )
    assert_equal( src_file, file.node_info[:src] )
    assert_equal( @plugin, file.node_info[:processor] )
    assert_equal( false, file.node_info[:preprocess] )
    assert_same( file, @plugin.create_node( src_file, root, {} ) )

    # ERB preprocessed file
    src_file = File.join( @manager.param_for_plugin( 'Core/Configuration', 'srcDir' ), 'embedded.rhtml' )
    file = @plugin.create_node( src_file, root, {'hallo'=>'hallo', 'title'=>'title'} )
    assert_equal( 'embedded.html', file.path )
    assert_equal( 'title', file['title'] )
    assert_equal( 'hallo', file['hallo'] )
    assert_equal( src_file, file.node_info[:src] )
    assert_equal( @plugin, file.node_info[:processor] )
    assert_equal( true, file.node_info[:preprocess] )
    assert_same( file, @plugin.create_node( src_file, root, {} ) )
  end

  def test_write_node
    root = @manager['Core/FileHandler'].instance_eval { create_root_node }
    root.write_node

    # normal file
    check_write_node( root, 'file1.page' )

    # ERB preprocessed file
    file = check_write_node( root, 'embedded.rhtml' )
    assert_equal( "true\n", File.read( file.full_path ) )
  ensure
    FileUtils.rm_r( root.full_path, :force => true )
  end

  def check_write_node( root, file )
    src_file = File.join( @manager.param_for_plugin( 'Core/Configuration', 'srcDir' ), file )
    file = @plugin.create_node( src_file, root, {} )

    file.write_node
    assert( File.exists?( file.full_path ) )
    assert( !@manager['Core/FileHandler'].file_modified?( file.node_info[:src], file.full_path ) )
    FileUtils.touch( file.node_info[:src] )
    file.write_node
    assert( !@manager['Core/FileHandler'].file_modified?( file.node_info[:src], file.full_path ) )
    file
  end

end

