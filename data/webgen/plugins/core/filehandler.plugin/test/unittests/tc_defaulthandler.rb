module FileHandlerTests

  class DefaultHandlerTest < Webgen::PluginTestCase

    plugin_to_test 'File/DefaultHandler'

    def setup
      super
      @manager.load_plugin_bundle( fixture_path( 'samplehandler.plugin' ) )
    end

    def param( param, plugin, cur_val )
      if [plugin, param] == ['File/DefaultHandler', 'linkToCurrentPage'] && @link_to_current
        [true, @link_to_current]
      else
        super
      end
    end

    def test_accessors
      plugin = @manager['Test/SampleFileHandler']
      plugin.instance_eval { register_path_pattern 'ccc' }
      plugin.instance_eval { register_path_pattern 'ddd', 30 }
      plugin.instance_eval { register_extension 'ggg' }
      plugin.instance_eval { register_extension 'hhh', 40 }

      patterns = plugin.path_patterns.sort
      [
       [10, 'bbb'],
       [20, @plugin.class::EXTENSION_PATH_PATTERN % ['fff']],
       [30, 'ddd'],
       [40, @plugin.class::EXTENSION_PATH_PATTERN % ['hhh']],
       [@plugin.class::DEFAULT_RANK, 'ccc'],
       [@plugin.class::DEFAULT_RANK, 'aaa'],
       [@plugin.class::DEFAULT_RANK, @plugin.class::EXTENSION_PATH_PATTERN % ['ggg']],
       [@plugin.class::DEFAULT_RANK, @plugin.class::EXTENSION_PATH_PATTERN % ['eee']]
      ].each_with_index do |p, index|
        if p[0] == @plugin.class::DEFAULT_RANK
          assert( patterns.include?( p ), "#{p} missing" )
        else
          assert_equal( p, patterns[index] )
        end
      end
    end

    def test_methods_for_subclasses
      assert_raise( NotImplementedError ) { @plugin.create_node( nil, nil, nil ) }
      assert_equal( nil, @plugin.write_info( nil ) )
    end

    def test_node_for_lang
      root = Node.new( nil, 'root/')
      node_de = Node.new( root, 'path.html', 'path.page' )
      node_en = Node.new( root, 'path.en.html', 'path.page' )
      node_no_lang = Node.new( root, 'otherpath', 'path.page' )
      de = Webgen::LanguageManager.language_for_code( 'de' )
      en = Webgen::LanguageManager.language_for_code( 'en' )
      es = Webgen::LanguageManager.language_for_code( 'es' )
      node_de.meta_info['lang'] = de
      node_en.meta_info['lang'] = en

      assert_equal( node_de, @plugin.node_for_lang( node_de, de ) )
      assert_equal( node_en, @plugin.node_for_lang( node_de, en ) )
      assert_equal( node_no_lang, @plugin.node_for_lang( node_de, es ) )
    end

    def test_link_from
      refNode = Node.new( nil, 'path' )
      node = Node.new( refNode, '#frag' )
      node['title'] = 'title'

      assert_equal( '<a href="#frag">title</a>', @plugin.link_from( node, refNode ) )
      assert_equal( '<a href="#frag">link_text</a>',
                    @plugin.link_from( node, refNode, :link_text => 'link_text' ) )
      assert_equal( '<a attr1="val1" href="#frag">link_text</a>',
                    @plugin.link_from( node, refNode, :link_text => 'link_text', 'attr1' => 'val1' ) )
      assert_equal( '<a href="#frag">link_text</a>',
                    @plugin.link_from( node, refNode, :link_text => 'link_text', :attr1 => 'val1' ) )

      node['linkAttrs'] = {:link_text => 'Default Text', 'class'=>'help'}
      assert_equal( '<a attr1="val1" class="help" href="#frag">link_text</a>',
                    @plugin.link_from( node, refNode, :link_text => 'link_text', 'attr1' => 'val1' ) )

      # Test param setting
      node['linkAttrs'] = nil
      @link_to_current = true
      assert_equal( '<a href="#frag">title</a>', @plugin.link_from( node, node ) )
      @link_to_current = false
      assert_equal( '<span>title</span>', @plugin.link_from( node, node ) )
    end

    def test_node_exist
      root = Node.new( nil, 'root/')
      node = Node.new( root, 'path.html', 'path.page' )
      dir = Node.new( root, 'dir/' )
      assert_equal( node, @plugin.node_exist?( root, 'path.html') )
      assert_equal( node, @plugin.node_exist?( root, 'path.html/') )
      assert_equal( dir, @plugin.node_exist?( root, 'dir') )
      assert_equal( dir, @plugin.node_exist?( root, 'dir/') )
      assert_equal( nil, @plugin.node_exist?( root, 'non_existing') )
    end

  end

end
