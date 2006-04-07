require 'find'
require 'fileutils'
require 'webgen/test'
require 'webgen/node'

class FileHandlerTest < Webgen::PluginTestCase

  #TODO think about runtime depdencies  (e.g. CorePlugins::Configuration for FileHandlers::FileHandler)
  #     ie. ones which are not required for initializing, but for running
  plugin_files [
    'webgen/plugins/filehandlers/filehandler.rb',
    'webgen/plugins/coreplugins/configuration.rb',
    'webgen/plugins/filehandlers/directory.rb',
    fixture_path( 'sample_plugin.rb' ),
  ]
  plugin_to_test 'FileHandlers::FileHandler'

  SAMPLE_SITE = fixture_path( '../sample_site/' )

  def setup
    super
    self.class.class_eval "class ::FileHandlers::FileHandler
           public :find_all_files
           public :find_files_for_handlers
           public :create_root_node
           public :create_node
           public :build_tree
         end"
    @manager.plugin_config = self
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


  def test_file_modified
    modified = fixture_path( 'modified' )
    unmodified = fixture_path( 'unmodified' )

    assert( @plugin.file_modified?( unmodified, modified ) )
    assert( !@plugin.file_modified?( unmodified, unmodified ) )
    FileUtils.touch( modified )
    assert( !@plugin.file_modified?( unmodified, modified ) )
    assert( @plugin.file_modified?( modified, unmodified ) )
  ensure
    FileUtils.rm( modified, :force => true )
  end

  def test_find_all_files
    found_files = @plugin.find_all_files
    files = find_in_sample_dir {|p| true }
    assert_equal( files, found_files )
  end

  def test_find_files_for_handlers
    found_files = @plugin.find_files_for_handlers
    files = find_in_sample_dir {|path| path =~ /\.page$/}

    assert_equal( 2, found_files.length )
    assert( found_files.keys.include?( @manager['SampleHandler'] ) )
    assert_equal( files, found_files[@manager['SampleHandler']] )
  end

  def test_create_root_node
    all_files = @plugin.find_all_files
    files_for_handlers = @plugin.find_files_for_handlers
    srcDir = @manager.param_for_plugin( 'CorePlugins::Configuration', 'srcDir' ) + '/'
    outDir = @manager.param_for_plugin( 'CorePlugins::Configuration', 'outDir' ) + '/'

    dir_handler = @manager.plugins.delete( 'FileHandlers::DirectoryHandler' )
    root = @plugin.create_root_node( all_files, files_for_handlers )
    assert_nil( root )

    @manager.plugins['FileHandlers::DirectoryHandler'] = dir_handler
    root = @plugin.create_root_node( all_files, files_for_handlers )
    assert_kind_of( Node, root )
    assert_equal( '', root['title'] )
    assert_equal( outDir, root.path )
    assert_equal( root.path, root.full_path )
    assert_equal( srcDir, root.node_info[:src] )

    assert( !all_files.include?( srcDir ) )
    assert( !files_for_handlers[@manager['FileHandlers::DirectoryHandler']].include?( srcDir ) )
  end

  def test_create_node_dir
    all_files = @plugin.find_all_files
    files_for_handlers = @plugin.find_files_for_handlers
    dirs = find_in_sample_dir {|path| File.directory?(path)}

    root_node = @plugin.create_root_node( all_files, files_for_handlers )
    dir_handler = @manager['FileHandlers::DirectoryHandler']

    max_dir = dirs.max

    dir = @plugin.create_node( max_dir, root_node, dir_handler )
    assert_not_nil( dir )
    assert_equal( File.join( File.basename( max_dir ), '/' ), dir.path )
    assert( dir.is_directory? )
    n = root_node
    while n.has_children?
      assert( n.is_directory? )
      assert_equal( 1, n.children.length, "node: #{n.children.collect{|c| c.path}.inspect}" )
      n = n.children[0]
    end

    dir1 = @plugin.create_node( max_dir, root_node, dir_handler )
    assert_same( dir, dir1 )
  end

  def test_create_node_file
    all_files = @plugin.find_all_files
    files_for_handlers = @plugin.find_files_for_handlers
    pages = find_in_sample_dir {|path| path =~ /\.page$/}

    root_node = @plugin.create_root_node( all_files, files_for_handlers )
    dir_handler = @manager['FileHandlers::DirectoryHandler']
    page_handler = @manager['SampleHandler']

    max_page = pages.max
    page = @plugin.create_node( max_page, root_node, page_handler )
    assert_not_nil( page )
    assert_equal( File.basename( max_page ), page.path )
    assert( page.is_file? )

    page1 = @plugin.create_node( max_page, root_node, page_handler )
    assert_same( page, page1 )
  end

  def test_build_tree
    outDir = @manager.param_for_plugin( 'CorePlugins::Configuration', 'outDir' ) + '/'

    tree = @plugin.build_tree
    assert_not_nil( tree )
    assert_equal( outDir, tree.full_path )
    assert_not_nil( tree.resolve_node( 'dir1/dir11/file111.page' ) )

    nr_paths_on_disc = find_in_sample_dir {|p| true }.length

    def calc_length( tree ); tree.children.inject( 1 ) {|memo,c| memo += calc_length( c ) }; end

    assert( calc_length( tree ), nr_paths_on_disc )
  end

end

class DefaultFileHandlerTest < Webgen::PluginTestCase

  plugin_files ['webgen/plugins/filehandlers/filehandler.rb']
  plugin_to_test 'FileHandler::DefaultFileHandler'

  def setup
    super
    @plugin1 = FileHandlers::DefaultFileHandler.new( @manager )
  end

  def test_initialization
    assert_nil( @plugin )
  end

  def test_accessors
    self.class.class_eval( <<-EVAL_END )
    class ::FileHandlers::DefaultFileHandler
        handle_path_pattern 'first'
        handle_path_pattern 'second'
        handle_extension 'fff'
        handle_extension 'ggg'

        public :handle_extension
        public :handle_path_pattern
    end
    EVAL_END
    @plugin1.handle_path_pattern 'third'
    @plugin1.handle_path_pattern 'fourth'
    @plugin1.handle_extension 'hhh'
    @plugin1.handle_extension 'iii'

    ['first', 'second', 'third', 'fourth',
      FileHandlers::DefaultFileHandler::EXTENSION_PATH_PATTERN % ['fff'],
      FileHandlers::DefaultFileHandler::EXTENSION_PATH_PATTERN % ['ggg'],
      FileHandlers::DefaultFileHandler::EXTENSION_PATH_PATTERN % ['hhh'],
      FileHandlers::DefaultFileHandler::EXTENSION_PATH_PATTERN % ['iii']
    ].each do |p|
      assert( @plugin1.path_patterns.include?( p ), "#{p} missing" )
    end
  end

  def test_methods_for_subclasses
    assert_raise( NotImplementedError ) { @plugin1.create_node( nil, nil ) }
    assert_raise( NotImplementedError ) { @plugin1.write_node( nil ) }
  end

  def test_node_for_lang
    node = Node.new( 'path', nil )
    node.meta_info['lang'] = ::Webgen::LanguageManager.language_for_code( 'de' )

    assert_nil( @plugin1.node_for_lang( node, 'en' ) )
    assert_equal( node, @plugin1.node_for_lang( node, 'de' ) )
    assert_equal( node, @plugin1.node_for_lang( node, 'ger' ) )
    assert_equal( node, @plugin1.node_for_lang( node, 'deu' ) )
  end

  def test_link_from
    refNode = Node.new( nil, 'path' )
    node = Node.new( refNode, '#frag' )
    node['title'] = 'title'

    assert_equal( '<a href="#frag">title</a>', @plugin1.link_from( node, refNode ) )
    assert_equal( '<a href="#frag">link_text</a>',
                  @plugin1.link_from( node, refNode, :link_text => 'link_text' ) )
    assert_equal( '<a attr1="val1" href="#frag">link_text</a>',
                  @plugin1.link_from( node, refNode, :link_text => 'link_text', :attr1 => 'val1' ) )
  end

end
