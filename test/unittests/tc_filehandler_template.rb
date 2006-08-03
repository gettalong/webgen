require 'webgen/test'

class TemplateFileHandlerTest < Webgen::PluginTestCase

  plugin_files [
    'webgen/plugins/filehandlers/filehandler.rb',
    'webgen/plugins/filehandlers/template.rb',
    'webgen/plugins/filehandlers/directory.rb',
  ]
  plugin_to_test 'FileHandlers::TemplateFileHandler'

  def test_initialization
    assert_not_nil( @plugin )
  end

  def test_create_node
    root = @manager['FileHandlers::FileHandler'].instance_eval { create_root_node( find_all_files, find_files_for_handlers ) }
    file = sample_site( 'src/default.template' )
    node = @plugin.create_node( file, root )

    assert_not_nil( node )
    assert_equal( File.basename( file ), node.path )
    assert_equal( file, node.node_info[:src] )
    assert_equal( File.basename( file ), node.node_info[:pagename] )
    assert_equal( File.basename( file ), node.node_info[:local_pagename] )
    assert_equal( @plugin, node.node_info[:processor] )
  end

  def test_templates_for_node
    root = @manager['FileHandlers::FileHandler'].instance_eval { build_tree }

    default_t = root.resolve_node( 'default.template' )
    assert_equal( [], default_t.templates_for_node )

    test_t = root.resolve_node( 'test.template' )
    assert_equal( [default_t], test_t.templates_for_node )

    root.del_child( default_t )
    assert_equal( [default_t], test_t.templates_for_node )
    root.add_child( default_t )

    invalid_t = root.resolve_node( 'invalid.template' )
    assert_equal( [default_t], invalid_t.templates_for_node )

    chained_t = root.resolve_node( 'chained.template' )
    assert_equal( [default_t, test_t], chained_t.templates_for_node )
  end

  def test_get_default_template
    root = Node.new( nil, '/' )
    template = Node.new( root, 'default.template' )
    dir1 = Node.new( root, 'dir1/' )

    assert_equal( template, @plugin.instance_eval { get_default_template( root ) })
    assert_equal( template, @plugin.instance_eval { get_default_template( dir1 ) })
    root.del_child( template )
    assert_nil( @plugin.instance_eval { get_default_template( root ) })
  end

end
