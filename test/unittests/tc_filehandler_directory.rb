require 'fileutils'
require 'webgen/test'

class DirNodeTest < Webgen::PluginTestCase

  plugin_files [
    'webgen/plugins/filehandlers/directory.rb'
  ]

  def test_accessors
    dir = FileHandlers::DirectoryHandler::DirNode.new( nil, 'dir/', {'test'=>'test'} )
    assert_equal( 'Dir', dir['title'] )
    assert_equal( 'test', dir['test'] )
  end

  def test_order_info
    dir = FileHandlers::DirectoryHandler::DirNode.new( nil, 'dir/' )
    dir.node_info[:processor] = @manager['FileHandlers::DirectoryHandler']

    assert_equal( 0, dir.order_info )

    index = Node.new( dir, 'index.page' )
    dir.meta_info.delete( 'indexFile' )
    assert_equal( 0, dir.order_info )

    dir['indexFile'] = 'index.page'
    index['orderInfo'] = 1
    assert_equal( 1, dir.order_info )

    dir['orderInfo'] = 2
    assert_equal( 2, dir.order_info )
  end

  def test_index_file
    dir = FileHandlers::DirectoryHandler::DirNode.new( nil, 'dir/' )
    dir.node_info[:processor] = @manager['FileHandlers::DirectoryHandler']

    assert_nil( dir['indexFile'] )

    index = Node.new( dir, 'index.page' )

    dir['indexFile'] = index
    assert_equal( index, dir['indexFile'] )

    dir['indexFile'] = 'index.page'
    assert_equal( index, dir['indexFile'] )

    dir['indexFile'] = 'index1.page'
    assert_equal( nil, dir['indexFile'] )
    dir['indexFile'] = 'index1.page'
    index.path = 'index1.page'
    assert_equal( index, dir['indexFile'] )

    index.path = 'index.page'
    dir['indexFile'] = nil
    assert_equal( nil, dir['indexFile'] )
  end

end

class DirectoryHandlerTest < Webgen::PluginTestCase

  plugin_files [
    'webgen/plugins/filehandlers/directory.rb',
    base_fixture_path( 'tc_filehandler_filehandler/sample_plugin.rb' )
  ]
  plugin_to_test 'FileHandlers::DirectoryHandler'

  def setup
    super
    @dirs = find_in_sample_site {|path| path =~ /\/$/ }.collect {|p| p.sub(/^#{sample_site( 'src' )}/, sample_site( 'out' ) )}
    @root_dir = @dirs.min
    @max_dir = @dirs.max
  end

  def test_create_node
    root = @plugin.create_node( @root_dir, nil, {} )
    dir = @plugin.create_node( @max_dir, root, {'test'=>'yes'} )
    assert_equal( 'yes', dir['test'] )
    dir1 = @plugin.create_node( @max_dir, root, {'test'=>'no'} )
    assert_equal( 'yes', dir1['test'] )
    assert_same( dir, dir1 )
    assert_equal( File.basename( @max_dir ).capitalize, dir['title'] )
  end

  def test_write_node
    root = @plugin.create_node( @root_dir, nil, {} )
    root.path = @root_dir
    dir_node = @plugin.create_node( @max_dir, root, {} )
    dir_node.write_node
    assert( File.directory?( dir_node.full_path ) )
  ensure
    FileUtils.rm_r( @root_dir, :force => true )
  end

  def test_recursive_create_path
    root = @plugin.create_node( @root_dir, nil, {} )
    root.path = @root_dir
    root.node_info[:src] = @root_dir
    dir_node = @plugin.recursive_create_path( @max_dir.sub( /^#{@root_dir}/, '' ), root )
    dir_node.write_node
    assert( File.directory?( @max_dir ) )
  ensure
    FileUtils.rm_r( @root_dir, :force => true )
  end

  def test_node_for_lang
    # directory with index file
    root = @manager['FileHandlers::FileHandler'].instance_eval { build_tree }
    assert_equal( root.resolve_node( 'index.en.html' ), root.node_for_lang( Webgen::LanguageManager.language_for_code( 'en' ) ) )
    assert_equal( root.resolve_node( 'index.de.html' ), root.node_for_lang( Webgen::LanguageManager.language_for_code( 'de' ) ) )

    # directory without index file
    dir1 = root.resolve_node( 'dir1' )
    assert_equal( dir1, dir1.node_for_lang( Webgen::LanguageManager.language_for_code( 'de' ) ) )
  end

  def test_link_from
    root = @manager['FileHandlers::FileHandler'].instance_eval { build_tree }

    file11 = root.resolve_node( 'dir1/file11.html' )
    assert_equal( '<a href="../index.en.html"></a>', root.link_from( file11 ) )
    assert_equal( '<a href="index.de.html">TestLink</a>',
                  root.link_from( root.resolve_node( 'index.de.html' ), {:link_text => 'TestLink' } ) )

    dir1 = root.resolve_node( 'dir1' )
    assert_equal( '<a href="./">Dir1</a>', dir1.link_from( file11 ) )
    assert_equal( '<a href="dir1/">TestLink</a>', dir1.link_from( root, {:link_text => 'TestLink' } ) )
  end

end

