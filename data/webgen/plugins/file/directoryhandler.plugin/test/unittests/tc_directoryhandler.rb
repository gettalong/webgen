require 'fileutils'
require 'webgen/test'

class DirNodeTest < Webgen::PluginTestCase

  plugin_to_test 'File/DirectoryHandler'

  def setup
    super
    @file_info = @manager::Core::FileHandler::FileInfo.new( 'dir/' )
    @file_info.meta_info.update( {'test'=>'test'} )
  end

  def test_accessors
    dir = @manager::FileHandlers::DirectoryHandler::DirNode.new( nil, 'dir/', @file_info )
    assert_equal( 'Dir', dir['title'] )
    assert_equal( 'test', dir['test'] )
  end

  def test_index_file
    dir = @manager::FileHandlers::DirectoryHandler::DirNode.new( nil, 'dir/', @file_info )
    dir.node_info[:processor] = @manager['File/DirectoryHandler']

    assert_nil( dir['indexFile'] )
    dir.node_info.delete(:indexFile)

    index = Node.new( dir, 'index.html', 'index.html' )

    dir['indexFile'] = 'index.html'
    assert_equal( dir['indexFile'], index  ) # order changed because sothat DelegateIndexNode#== is invoked
    dir.node_info.delete(:indexFile)

    dir['indexFile'] = 'index1.html'
    assert_equal( nil, dir['indexFile'] )
    dir.node_info.delete(:indexFile)

    dir['indexFile'] = nil
    assert_equal( nil, dir['indexFile'] )
  end

end

class DirectoryHandlerTest < Webgen::PluginTestCase

  plugin_to_test 'File/DirectoryHandler'

  def setup
    super
    @dirs = find_in_sample_site {|path| path =~ /\/$/ }.collect {|p| p.sub(/^#{sample_site( Webgen::SRC_DIR )}/, sample_site( 'out' ) )}
    @root_dir = @dirs.min
    @max_dir = @dirs.max
  end

  def file_info( path, meta_info = {} )
    file_info = @manager::Core::FileHandler::FileInfo.new( path )
    file_info.meta_info.update( meta_info )
    file_info
  end

  def test_create_node
    root = @plugin.create_node( nil, file_info( @root_dir ) )
    assert_equal( @plugin, root.node_info[:processor] )
    assert_equal( @root_dir, root.node_info[:src] )

    dir = @plugin.create_node( root, file_info( @max_dir, {'test'=>'yes'} ) )
    assert_equal( 'yes', dir['test'] )

    dir1 = @plugin.create_node( root, file_info( @max_dir, {'test'=>'no'} ) )
    assert_equal( 'yes', dir1['test'] )
    assert_same( dir, dir1 )
    assert_equal( File.basename( @max_dir ).capitalize, dir['title'] )
  end

  def test_write_info
    root = @plugin.create_node( nil, file_info( @root_dir ) )
    root.path = @root_dir
    dir_node = @plugin.create_node( root, file_info( @root_dir ) )
    write_info = dir_node.write_info
    assert_equal( dir_node.node_info[:src], write_info[:src] )
  end

  def test_recursive_create_path
    root = @plugin.create_node( nil, file_info( @root_dir ) )
    root.path = @root_dir
    dir_node = @plugin.recursive_create_path( @max_dir.sub( /^#{@root_dir}/, '' ), root )
    write_info = dir_node.write_info
    assert_equal( dir_node.node_info[:src], write_info[:src] )
  end

  def test_node_for_lang
    # directory with index file
    root = @manager['Core/FileHandler'].instance_eval { build_tree }
    assert( root.node_for_lang( Webgen::LanguageManager.language_for_code( 'en' ) ) == root.resolve_node( 'index.en.html' ) )
    assert( root.node_for_lang( Webgen::LanguageManager.language_for_code( 'de' ) ) == root.resolve_node( 'index.de.html' ) )

    # directory without index file
    dir1 = root.resolve_node( 'dir' )
    assert( dir1.node_for_lang( Webgen::LanguageManager.language_for_code( 'de' ) ) == dir1 )
  end

  def test_link_from
    root = @manager['Core/FileHandler'].instance_eval { build_tree }
    de = Webgen::LanguageManager.language_for_code( 'de' )
    en = Webgen::LanguageManager.language_for_code( 'en' )

    root['title'] = 'Root'
    root.node_for_lang( en )['directoryName'] = 'RootEN'

    file = root.resolve_node( 'dir/file.html' )
    assert_equal( '<a href="../">Root</a>', root.link_from( file ) )
    assert_equal( '<a href="../index.html">RootEN</a>', root.node_for_lang( en ).link_from( file ) )
    assert_equal( '<span>TestLink</span>',
                  root.node_for_lang( de ).
                  link_from( root.resolve_node( 'index.de.html' ), {:link_text => 'TestLink' } ) )

    dir = root.resolve_node( 'dir' )
    assert_equal( '<a href="./">Dir</a>', dir.link_from( file ) )
    assert_equal( '<a href="dir/">TestLink</a>', dir.link_from( root, {:link_text => 'TestLink' } ) )
  end

end

