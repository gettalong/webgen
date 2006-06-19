require 'yaml'
require 'webgen/test'

class FragmentNodeTest < Webgen::PluginTestCase

  plugin_files [
    'webgen/plugins/filehandlers/page.rb',
  ]

  def test_accessors
    @node = FileHandlers::PageFileHandler::FragmentNode.new( nil, 'test' )
    assert_same( @node, @node.node_info[:processor] )
    assert( !@node.meta_info['inMenu'] )
  end

end


class PageNodeTest < Webgen::PluginTestCase

  plugin_files [
    'webgen/plugins/filehandlers/page.rb',
  ]

  def setup
    super
    @testdata = YAML::load( File.read( fixture_path( 'testdata.yaml' ) ) )
    @data = WebPageData.new( @testdata['data'], 'default'=>proc{|c| c} )
    @node = FileHandlers::PageFileHandler::PageNode.new( nil, 'test.html', @data )
  end

  def test_initialization
    assert_same( @data, @node.node_info[:pagedata] )
    @testdata['sections'].each do |name|
      assert_not_nil( @node.resolve_node( name ) )
    end
  end

  def test_match
    @node.node_info[:local_pagename] = 'test.de.page'
    @node.node_info[:pagename] = 'test.page'
    assert( @node =~ 'test.de.page' )
    assert( @node =~ 'test.de.page#something' )
    assert( @node =~ 'test.page' )
    assert( @node =~ 'test.page#something' )
    assert( @node =~ 'test.html' )
    assert( @node =~ 'test.html#something' )
  end

end


class PageHandlerTest < Webgen::FileHandlerTestCase

  plugin_files [
    'webgen/plugins/filehandlers/directory.rb',
    'webgen/plugins/filehandlers/page.rb',
  ]
  plugin_to_test 'FileHandlers::PageFileHandler'

  def setup
    super
    @testdata = YAML::load( File.read( fixture_path( 'testdata.yaml' ) ) )
    self.class.class_eval "class ::FileHandlers::PageFileHandler
           public :analyse_file_name
           public :create_output_name
         end"
    @manager.plugins['ContentFormatters::Default'] = Object.new
    def (@manager.plugins['ContentFormatters::Default']).formatters
      {'default' => proc {|c| c}, 'textile' => proc {|c| c}}
    end
  end

  def test_initialization
    assert_not_nil( @plugin )
  end

  def test_create_node_from_data
    root = @manager['FileHandlers::FileHandler'].instance_eval { create_root_node( find_all_files, find_files_for_handlers ) }
    node = @plugin.create_node_from_data( 'index.page', root, @testdata['data'] )

    assert_equal( 'index.html', node.path )
    assert_equal( 'index.page', node.node_info[:pagename] )
    assert_equal( 'index.en.page', node.node_info[:local_pagename] )
    assert_equal( 'index.page', node.node_info[:src] )
    assert_equal( @plugin, node.node_info[:processor] )
    assert_equal( 'Index', node['title'] )
    assert_equal( 0, node['orderInfo'] )
    assert_equal( Webgen::LanguageManager.language_for_code( 'en' ), node['lang'] )

    node1 = @plugin.create_node_from_data( 'index.page', root, @testdata['data'] )
    assert_same( node, node1 )
  end

  def test_render_node
    flunk
  end

  def test_node_for_lang
    root = @manager['FileHandlers::FileHandler'].instance_eval { build_tree }

    index = root.resolve_node( 'index.page' )
    de = Webgen::LanguageManager.language_for_code( 'de' )
    en = Webgen::LanguageManager.language_for_code( 'en' )
    eo = Webgen::LanguageManager.language_for_code( 'eo' )

    assert_equal( root.resolve_node( 'index.de.page' ), @plugin.node_for_lang( index, de ) )
    assert_equal( root.resolve_node( 'index.en.page' ), @plugin.node_for_lang( index, en ) )
    assert_nil( @plugin.node_for_lang( index, eo ) )
  end

  def test_link_from
    root = @manager['FileHandlers::FileHandler'].instance_eval { build_tree }
    index_en = root.resolve_node( 'index.en.page' )
    index_de = root.resolve_node( 'index.de.page' )
    file1 = root.resolve_node( 'file1.page' )

    assert_equal( '<a href="index.html">Index</a>', @plugin.link_from( index_de, file1 ) )
    assert_equal( 'File1', @plugin.link_from( file1, index_de ) )
  end


  def analyse_file_name( struct )
    assert_equal( struct, @plugin.analyse_file_name( struct.filename ) )
  end

  def test_analyse_file_name
    analyse_file_name( OpenStruct.new( {'lang' => @manager.param_for_plugin( 'CorePlugins::Configuration', 'lang' ),
                                        'filename' => 'default.page',
                                        'name' => 'default', 'orderInfo' => 0,
                                        'title' => 'Default', 'useLangPart' => false } ) )
    analyse_file_name( OpenStruct.new( {'lang' => 'de',
                                        'filename' => 'default.de.page',
                                        'name' => 'default', 'orderInfo' => 0,
                                        'title' => 'Default', 'useLangPart' => true } ) )
    analyse_file_name( OpenStruct.new( {'lang' => 'eo',
                                        'filename' => '12.Hello webpage_hello.eo.page',
                                        'name' => 'Hello webpage_hello', 'orderInfo' => 12,
                                        'title' => 'Hello webpage hello', 'useLangPart' => true } ) )
    analyse_file_name( OpenStruct.new( {'lang' => @manager.param_for_plugin( 'CorePlugins::Configuration', 'lang' ),
                                        'filename' => 'default.e.page',
                                        'name' => 'default', 'orderInfo' => 0,
                                        'title' => 'Default', 'useLangPart' => false } ) )
    analyse_file_name( OpenStruct.new( {'lang' => @manager.param_for_plugin( 'CorePlugins::Configuration', 'lang' ),
                                        'filename' => 'default.eadd.page',
                                        'name' => 'default', 'orderInfo' => 0,
                                        'title' => 'Default', 'useLangPart' => false } ) )
  end


  def check_output_name( expected, given, style, omitLang = false )
    assert_equal( expected, @plugin.create_output_name( @plugin.analyse_file_name( given ), style, omitLang ) )
  end

  def test_create_output_name
    style = [:name, ['.', :lang], '.html']
    check_output_name( 'index.de.html', 'index.de.page', style )
    check_output_name( 'index.html', 'index.de.page', style, true )
    check_output_name( 'index.html', 'index.en.page', style )

    style = [:name, '.', :lang, '.html']
    check_output_name( 'index.de.html', 'index.de.page', style )
    check_output_name( 'index..html', 'index.de.page', style, true )
    check_output_name( 'index..html', 'index.en.page', style )
  end

end
