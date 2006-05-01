require 'fileutils'
require 'webgen/test'
require 'webgen/node'
require 'webgen/config'

class DirectoryHandlerTest < Webgen::FileHandlerTestCase

  plugin_files [
    'webgen/plugins/filehandlers/filehandler.rb',
    'webgen/plugins/filehandlers/directory.rb',
    BASE_FIXTURE_PATH + 'tc_filehandler_filehandler/sample_plugin.rb'
  ]
  plugin_to_test 'FileHandlers::DirectoryHandler'

  SAMPLE_SITE = File.expand_path( fixture_path( '../sample_site/' ) ) + '/'

  def setup
    super
    @manager.plugin_config = self
    @dirs = find_in_sample_dir {|path| path =~ /\/$/ }.collect {|p| p.sub(/^#{SAMPLE_SITE + 'src'}/, SAMPLE_SITE + 'out' )}
    @root_dir = @dirs.min
    @max_dir = @dirs.max
  end

  def param_for_plugin( plugin_name, param )
    case [plugin_name, param]
    when ['CorePlugins::Configuration', 'srcDir'] then SAMPLE_SITE + 'src'
    when ['CorePlugins::Configuration', 'outDir'] then SAMPLE_SITE + 'out'
    else raise Webgen::PluginParamNotFound.new( plugin_name, param )
    end
  end

  def find_in_sample_dir
    files = Set.new
    Find.find( SAMPLE_SITE + 'src' ) do |path|
      Find.prune if File.basename( path ) =~ /^\./
      path += '/' if FileTest.directory?(path)
      files << path if yield( path )
    end
    files
  end


  def test_create_node
    root = @plugin.create_node( @root_dir, nil )
    dir = @plugin.create_node( @max_dir, root )
    dir1 = @plugin.create_node( @max_dir, root )
    assert_same( dir, dir1 )
    assert_equal( File.basename( @max_dir ), dir['title'] )
  end

  def test_write_node
    root = @plugin.create_node( @root_dir, nil )
    root.path = @root_dir
    dir_node = @plugin.create_node( @max_dir, root )
    dir_node.write_node
    assert( File.directory?( dir_node.full_path ) )
  ensure
    FileUtils.rm_r( @root_dir, :force => true )
  end

  def test_recursive_create_path
    root = @plugin.create_node( @root_dir, nil )
    root.path = @root_dir
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
    assert_equal( '<a href="./">dir1</a>', dir1.link_from( file11 ) )
    assert_equal( '<a href="dir1/">TestLink</a>', dir1.link_from( root, {:link_text => 'TestLink' } ) )
  end

end

