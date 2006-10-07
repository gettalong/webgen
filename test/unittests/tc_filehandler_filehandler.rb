require 'find'
require 'fileutils'
require 'webgen/test'
require 'webgen/node'
require 'webgen/config'

class FileHandlerTest < Webgen::PluginTestCase

  #TODO think about runtime depdencies  (e.g. Configuration for Core/FileHandler)
  #     ie. ones which are not required for initializing, but for running
  plugin_files [
    'webgen/plugins/filehandlers/filehandler.rb',
    'webgen/plugins/filehandlers/directory.rb',
    fixture_path( 'sample_plugin.rb' ),
  ]
  plugin_to_test 'Core/FileHandler'

  def setup
    @websiteDir = nil
    super
  end

  def param_for_plugin( plugin_name, param )
    if [plugin_name, param] == ['Core/Configuration', 'websiteDir']
      @websiteDir || super
    else
      super
    end
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
    found_files = @plugin.instance_eval {find_all_files}
    files = find_in_sample_site {|p| p != sample_site( Webgen::SRC_DIR ) + '/' }
    assert_equal( files, found_files )
  end

  def test_find_files_for_handlers
    files_for_handlers = @plugin.instance_eval {find_files_for_handlers}
    files = find_in_sample_site {|path| path =~ /\.page$/}

    assert_equal( 2, files_for_handlers.length )
    files_for_sample_handler = files_for_handlers.select {|r,p,f| p == @manager['SampleHandler']}
    assert_not_nil( files_for_sample_handler )
    assert_equal( files, files_for_sample_handler.first[2] )
  end

  def test_create_root_node
    srcDir = @manager.param_for_plugin( 'Core/Configuration', 'srcDir' ) + '/'
    outDir = @manager.param_for_plugin( 'Core/Configuration', 'outDir' ) + '/'

    dir_handler = @manager.plugins.delete( 'File/DirectoryHandler' )
    root = @plugin.instance_eval {create_root_node}
    assert_nil( root )

    @manager.plugins['File/DirectoryHandler'] = dir_handler
    root = @plugin.instance_eval {create_root_node}
    assert_kind_of( Node, root )
    assert_equal( '', root['title'] )
    assert_equal( outDir, root.path )
    assert_equal( root.path, root.full_path )
    assert_equal( srcDir, root.node_info[:src] )
  end

  def test_create_node_dir
    dirs = find_in_sample_site {|path| File.directory?(path)}

    root_node = @plugin.instance_eval {create_root_node}
    dir_handler = @manager['File/DirectoryHandler']

    max_dir = dirs.max

    dir = @plugin.create_node( max_dir.sub( /^#{root_node.node_info[:src]}/, ''), root_node, dir_handler )
    assert_not_nil( dir )
    assert_equal( File.join( File.basename( max_dir ), '/' ), dir.path )
    assert_equal( max_dir.sub(/^#{root_node.node_info[:src]}/, root_node.path), dir.full_path )
    assert( dir.is_directory? )

    n = root_node
    while n.has_children?
      assert( n.is_directory? )
      assert_equal( 1, n.children.length, "node: #{n.children.collect{|c| c.path}.inspect}" )
      n = n.children[0]
    end

    dir1 = @plugin.create_node( max_dir.sub( /^#{root_node.node_info[:src]}/, ''), root_node, dir_handler )
    assert_same( dir, dir1 )
  end

  def test_create_node_file
    pages = find_in_sample_site {|path| path =~ /\.page$/}

    root_node = @plugin.instance_eval {create_root_node}
    dir_handler = @manager['File/DirectoryHandler']
    page_handler = @manager['SampleHandler']

    max_page = pages.max
    page = @plugin.create_node( max_page.sub( /^#{root_node.node_info[:src]}/, ''), root_node, page_handler )
    assert_not_nil( page )
    max_page_outpath = File.join( File.dirname( max_page.sub(/^#{root_node.node_info[:src]}/, root_node.path) ),
                                  page_handler.class.out_name( max_page ) )
    assert_equal( max_page_outpath, page.full_path )
    assert( page.is_file? )

    page1 = @plugin.create_node( max_page.sub( /^#{root_node.node_info[:src]}/, ''), root_node, page_handler )
    assert_same( page, page1 )
  end

  def test_build_tree
    outDir = @manager.param_for_plugin( 'Core/Configuration', 'outDir' ) + '/'

    tree = @plugin.instance_eval {build_tree}
    assert_not_nil( tree )
    assert_equal( outDir, tree.full_path )
    assert_equal( 6, tree.children.size )
    assert_not_nil( tree.resolve_node( 'dir1/dir11/file111.html' ) )

    nr_paths_on_disc = find_in_sample_site {|p| true }.length

    def calc_length( tree ); tree.children.inject( 1 ) {|memo,c| memo += calc_length( c ) }; end

    assert( calc_length( tree ), nr_paths_on_disc )
  end

  def test_load_meta_info_backing_file
    @websiteDir = fixture_path('backing')
    assert( File.exists?( @websiteDir ) )
    @plugin.instance_eval { load_meta_info_backing_file }
    assert_equal({'key1'=>'value1'}, @plugin.instance_eval { @source_backing['file1'] })
    assert_equal({}, @plugin.instance_eval { @output_backing })
    @websiteDir = fixture_path('backing_empty')
    assert( File.exists?( @websiteDir ) )
    @plugin.instance_eval { @source_backing = nil; @output_backing = nil; load_meta_info_backing_file }
    assert_equal({}, @plugin.instance_eval { @source_backing })
  rescue
    puts $!
    @websiteDir = nil
  end

  def test_meta_info_for
    @plugin.instance_eval { @source_backing = {'/file'=>{'key'=>'novalue'}} }
    assert_equal( {'key'=>'value'}, @plugin.meta_info_for( @manager['SampleHandler'] ) )
    assert_equal( {'key'=>'novalue'}, @plugin.meta_info_for( @manager['SampleHandler'], '/file' ) )
    @plugin.instance_eval { @source_backing = {'file'=>{'key'=>'novalue'}} }
    assert_equal( {'key'=>'novalue'}, @plugin.meta_info_for( @manager['SampleHandler'], '/file' ) )
    assert_equal( {'key'=>'value'}, @plugin.meta_info_for( @manager['SampleHandler'] ) )
  end

  def test_handle_output_backing
    root = @plugin.instance_eval { create_root_node }
    node = Node.new( Node.new( root, 'dir/' ), 'test1.html' )
    node['test'] = 'yes'
    @plugin.instance_eval { @output_backing = {
        'api.html'=>{'url'=>'rdoc/index.html'},
        '/doc/test.html'=>{'url'=>'http://www.webgen.com'},
        'dir/test1.html'=>{'test'=>'no'}
      }}
    @plugin.instance_eval { handle_output_backing( root ) }

    # test virtual node creation
    assert_not_nil( root.resolve_node( 'rdoc/index.html' ) )
    assert_not_nil( root.resolve_node( 'api.html' ) )
    backed1 = root.resolve_node( 'api.html' )
    assert_equal( 'api.html', backed1.node_info[:reference] )
    assert_equal( @manager['File/VirtualFileHandler'], backed1.node_info[:processor] )

    backed2 = root.resolve_node( 'doc/test.html' )
    assert_not_nil( backed2 )

    assert_equal( '<a href="../rdoc/index.html">rdoc/index.html</a>', backed1.link_from( node ) )
    assert_equal( '<a href="http://www.webgen.com">http://www.webgen.com</a>', backed2.link_from( node ) )

    # test setting of meta infos for existing nodes
    assert_equal( 1, root.resolve_node( 'dir/' ).children.length )
    assert_equal( 'no', node['test'] )
  end

end

class DefaultHandlerTest < Webgen::PluginTestCase

  plugin_files ['webgen/plugins/filehandlers/filehandler.rb']
  plugin_to_test 'File/DefaultHandler'

  def setup
    super
    @defHandlerClass = @manager.plugin_class_for_name( 'File/DefaultHandler' )
    @plugin1 = @defHandlerClass.new( @manager )
  end

  def test_initialization
    assert_nil( @plugin )
  end

  def test_accessors
    @defHandlerClass.class_eval do
      register_path_pattern 'first'
      register_path_pattern 'second', 10
      register_extension 'fff'
      register_extension 'ggg', 20

      public :register_extension
      public :register_path_pattern
    end
    @plugin1.register_path_pattern 'third'
    @plugin1.register_path_pattern 'fourth', 30
    @plugin1.register_extension 'hhh'
    @plugin1.register_extension 'iii', 40

    patterns = @plugin1.path_patterns.sort
    [
     [10, 'second'],
     [20, @defHandlerClass::EXTENSION_PATH_PATTERN % ['ggg']],
     [30, 'fourth'],
     [40, @defHandlerClass::EXTENSION_PATH_PATTERN % ['iii']],
     [@defHandlerClass::DEFAULT_RANK, 'first'],
     [@defHandlerClass::DEFAULT_RANK, 'third'],
     [@defHandlerClass::DEFAULT_RANK, @defHandlerClass::EXTENSION_PATH_PATTERN % ['fff']],
     [@defHandlerClass::DEFAULT_RANK, @defHandlerClass::EXTENSION_PATH_PATTERN % ['hhh']]
    ].each_with_index do |p, index|
      if p[0] == @defHandlerClass::DEFAULT_RANK
        assert( patterns.include?( p ), "#{p} missing" )
      else
        assert_equal( p, patterns[index] )
      end
    end
  end

  def test_methods_for_subclasses
    assert_raise( NotImplementedError ) { @plugin1.create_node( nil, nil, nil ) }
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

    node['linkAttrs'] = {:link_text => 'Default Text', 'class'=>'help'}
    assert_equal( '<a attr1="val1" class="help" href="#frag">link_text</a>',
                  @plugin1.link_from( node, refNode, :link_text => 'link_text', :attr1 => 'val1' ) )
  end

end
