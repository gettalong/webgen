require 'find'
require 'fileutils'
require 'webgen/test'
require 'webgen/node'
require 'webgen/config'

class FileHandlerTest < Webgen::PluginTestCase

  #TODO think about runtime depdencies  (e.g. CorePlugins::Configuration for FileHandlers::FileHandler)
  #     ie. ones which are not required for initializing, but for running
  plugin_files [
    'webgen/plugins/filehandlers/filehandler.rb',
    'webgen/plugins/filehandlers/directory.rb',
    fixture_path( 'sample_plugin.rb' ),
  ]
  plugin_to_test 'FileHandlers::FileHandler'

  def setup
    super
    self.class.class_eval "class ::FileHandlers::FileHandler
           public :find_all_files
           public :find_files_for_handlers
           public :create_root_node
           public :create_node
           public :build_tree
         end"
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
    files = find_in_sample_site {|p| p != sample_site( 'src' ) + '/' }
    assert_equal( files, found_files )
  end

  def test_find_files_for_handlers
    files_for_handlers = @plugin.find_files_for_handlers
    files = find_in_sample_site {|path| path =~ /\.page$/}

    assert_equal( 2, files_for_handlers.length )
    files_for_sample_handler = files_for_handlers.select {|r,p,f| p == @manager['SampleHandler']}
    assert_not_nil( files_for_sample_handler )
    assert_equal( files, files_for_sample_handler.first[2] )
  end

  def test_create_root_node
    srcDir = @manager.param_for_plugin( 'CorePlugins::Configuration', 'srcDir' ) + '/'
    outDir = @manager.param_for_plugin( 'CorePlugins::Configuration', 'outDir' ) + '/'

    dir_handler = @manager.plugins.delete( 'FileHandlers::DirectoryHandler' )
    root = @plugin.create_root_node
    assert_nil( root )

    @manager.plugins['FileHandlers::DirectoryHandler'] = dir_handler
    root = @plugin.create_root_node
    assert_kind_of( Node, root )
    assert_equal( '', root['title'] )
    assert_equal( outDir, root.path )
    assert_equal( root.path, root.full_path )
    assert_equal( srcDir, root.node_info[:src] )
  end

  def test_create_node_dir
    dirs = find_in_sample_site {|path| File.directory?(path)}

    root_node = @plugin.create_root_node
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
    pages = find_in_sample_site {|path| path =~ /\.page$/}

    root_node = @plugin.create_root_node
    dir_handler = @manager['FileHandlers::DirectoryHandler']
    page_handler = @manager['SampleHandler']

    max_page = pages.max
    page = @plugin.create_node( max_page, root_node, page_handler )
    assert_not_nil( page )
    assert_equal( page_handler.class.out_name( max_page ), page.path )
    assert( page.is_file? )

    page1 = @plugin.create_node( max_page, root_node, page_handler )
    assert_same( page, page1 )
  end

  def test_build_tree
    outDir = @manager.param_for_plugin( 'CorePlugins::Configuration', 'outDir' ) + '/'

    tree = @plugin.build_tree
    assert_not_nil( tree )
    assert_equal( outDir, tree.full_path )
    assert_equal( 5, tree.children.size )
    assert_not_nil( tree.resolve_node( 'dir1/dir11/file111.html' ) )

    nr_paths_on_disc = find_in_sample_site {|p| true }.length

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
        register_path_pattern 'first'
        register_path_pattern 'second', 10
        register_extension 'fff'
        register_extension 'ggg', 20

        public :register_extension
        public :register_path_pattern
    end
    EVAL_END
    @plugin1.register_path_pattern 'third'
    @plugin1.register_path_pattern 'fourth', 30
    @plugin1.register_extension 'hhh'
    @plugin1.register_extension 'iii', 40

    patterns = @plugin1.path_patterns.sort
    [
     [10, 'second'],
     [20, FileHandlers::DefaultFileHandler::EXTENSION_PATH_PATTERN % ['ggg']],
     [30, 'fourth'],
     [40, FileHandlers::DefaultFileHandler::EXTENSION_PATH_PATTERN % ['iii']],
     [FileHandlers::DefaultFileHandler::DEFAULT_RANK, 'first'],
     [FileHandlers::DefaultFileHandler::DEFAULT_RANK, 'third'],
     [FileHandlers::DefaultFileHandler::DEFAULT_RANK, FileHandlers::DefaultFileHandler::EXTENSION_PATH_PATTERN % ['fff']],
     [FileHandlers::DefaultFileHandler::DEFAULT_RANK, FileHandlers::DefaultFileHandler::EXTENSION_PATH_PATTERN % ['hhh']]
    ].each_with_index do |p, index|
      if p[0] == FileHandlers::DefaultFileHandler::DEFAULT_RANK
        assert( patterns.include?( p ), "#{p} missing" )
      else
        assert_equal( p, patterns[index] )
      end
    end
  end

  def test_methods_for_subclasses
    assert_raise( NotImplementedError ) { @plugin1.create_node( nil, nil ) }
    assert_raise( NotImplementedError ) { @plugin1.write_node( nil ) }
  end

  def test_node_for_lang
    node = Node.new( nil, 'path' )
    de = Webgen::LanguageManager.language_for_code( 'de' )
    en = Webgen::LanguageManager.language_for_code( 'en' )
    assert_equal( node, @plugin1.node_for_lang( node, de ) )
    assert_equal( node, @plugin1.node_for_lang( node, en ) )
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
