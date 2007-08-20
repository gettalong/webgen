require 'webgen/test'
require 'webgen/node'
require 'webgen/config'

module CoreTests
  class FileHandlerTest < Webgen::PluginTestCase

    #plugin_files [fixture_path( 'sample_plugin.rb' )]
    plugin_to_test 'Core/FileHandler'

    def setup
      @websiteDir = nil
      super
    end

    def param( param, plugin, cur_val )
      if [plugin, param] == ['Core/Configuration', 'websiteDir'] && @websiteDir
        @websiteDir
      else
        super
      end
    end

    def test_analyse_filename
      check_proc = proc do |o, fn,oi,bn,lang,ext,cn,title|
        assert_equal( fn, o.filename )
        assert_equal( oi, o.meta_info['orderInfo'] )
        assert_equal( bn, o.basename )
        assert_equal( lang, o.meta_info['lang'] )
        assert_equal( ext, o.ext )
        assert_equal( cn, o.cn )
        assert_equal( title, o.meta_info['title'] )
      end
      de = Webgen::LanguageManager.language_for_code( 'de' )
      en = Webgen::LanguageManager.language_for_code( 'en' )
      check_proc.call( @manager::Core::FileHandler::FileInfo.new( '5.base_name-one.de.page'),
                       '5.base_name-one.de.page', 5, 'base_name-one', de,
                       'page', 'base_name-one.page', 'Base name one' )
      check_proc.call( @manager::Core::FileHandler::FileInfo.new( 'default.png'),
                       'default.png', 0, 'default', nil, 'png', 'default.png', 'Default' )
      check_proc.call( @manager::Core::FileHandler::FileInfo.new( 'default.en.png'),
                       'default.en.png', 0, 'default', en, 'png', 'default.png', 'Default' )
      check_proc.call( @manager::Core::FileHandler::FileInfo.new( 'default.deu.png'),
                       'default.deu.png', 0, 'default', de, 'png', 'default.png', 'Default' )
      check_proc.call( @manager::Core::FileHandler::FileInfo.new( 'default.template'),
                       'default.template', 0, 'default', nil, 'template', 'default.template', 'Default' )
    end

    def test_file_changed
      modified = fixture_path( 'modified' )
      unmodified = fixture_path( 'unmodified' )

      assert( @plugin.file_changed?( unmodified ) )
      @manager['Core/CacheManager'].data.merge!( @manager['Core/CacheManager'].new_data )
      assert( !@plugin.file_changed?( unmodified ) )
      assert( @plugin.file_changed?( unmodified, modified ) )
      FileUtils.touch( unmodified )
      assert( @plugin.file_changed?( unmodified ) )
    ensure
      FileUtils.rm( modified, :force => true )
    end

=begin
TODO make these tests go green :-)

add test to see if files with upper case extensions are resolved correctly

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
      assert_equal({'key1'=>'value1'}, @plugin.instance_eval { @source_backing['/file1'] })
      assert_equal({}, @plugin.instance_eval { @output_backing })
      @websiteDir = fixture_path('backing_empty')
      assert( File.exists?( @websiteDir ) )
      @plugin.instance_eval { @source_backing = nil; @output_backing = nil; load_meta_info_backing_file }
      assert_equal({}, @plugin.instance_eval { @source_backing })
    ensure
      @websiteDir = nil
    end

    def test_meta_info_for
      @plugin.instance_eval { @source_backing = {'/file'=>{'key'=>'novalue'},'ile'=>{'key'=>'false value'}} }
      assert_equal( {'key'=>'value'}, @plugin.meta_info_for( @manager['SampleHandler'] ) )
      assert_equal( {'key'=>'novalue'}, @plugin.meta_info_for( @manager['SampleHandler'], '/file' ) )
      assert_equal( {'key'=>'novalue'}, @plugin.meta_info_for( @manager['SampleHandler'], 'file' ) )

      @plugin.instance_eval { @source_backing = {'/file'=>{'key'=>'novalue'}} }
      assert_equal( {'key'=>'novalue'}, @plugin.meta_info_for( @manager['SampleHandler'], '/file' ) )
      assert_equal( {'key'=>'value'}, @plugin.meta_info_for( @manager['SampleHandler'] ) )

      @plugin.instance_eval { @source_backing = {'/dir'=>{'key'=>'novalue'}} }
      assert_equal( {'key'=>'novalue'}, @plugin.meta_info_for( @manager['SampleHandler'], 'dir' ) )
      assert_equal( {'key'=>'novalue'}, @plugin.meta_info_for( @manager['SampleHandler'], '/dir/' ) )
      assert_equal( {'key'=>'novalue'}, @plugin.meta_info_for( @manager['SampleHandler'], '/dir' ) )
      assert_equal( {'key'=>'novalue'}, @plugin.meta_info_for( @manager['SampleHandler'], 'dir/' ) )
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
=end

  end

end
