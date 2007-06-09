require 'yaml'
require 'webgen/test'

class PageHandlerTest < Webgen::PluginTestCase

  plugin_to_test 'File/PageHandler'


  def test_initialization
    assert_not_nil( @plugin )
  end

  def test_create_node
    root = @manager['Core/FileHandler'].instance_eval { create_root_node }
    data = ""
    file_info = @manager::Core::FileHandler::FileInfo.new( 'index.page' )
    file_info.meta_info.update( {'lang'=>'eo', 'test'=>'yes', 'orderInfo'=>6} )
    node = @plugin.create_node_from_data( root, file_info, data )

    assert_equal( 'index.eo.html', node.path )
    assert_equal( 'index.page', node.node_info[:src] )
    assert_equal( @plugin, node.node_info[:processor] )
    assert_equal( 'Index', node['title'] )
    assert_equal( 'yes', node['test'] )
    assert_equal( 6, node['orderInfo'] )
    assert_equal( Webgen::LanguageManager.language_for_code( 'epo' ), node['lang'] )

    node1 = @plugin.create_node_from_data( root, file_info, data )
    assert_same( node, node1 )
  end

  def test_write_info
    root = @manager['Core/FileHandler'].instance_eval { build_tree }
    file = root.resolve_node( 'file.de.html' )
    write_info = file.write_info
    assert_equal( "Template\n"+
                  "<p>Content true</p>\n"+
                  "Template", write_info[:data] )
  end

  def test_render_node
    root = @manager['Core/FileHandler'].instance_eval { build_tree }
    file = root.resolve_node( 'file.de.html' )

    assert_equal( "Template\n"+
                  "<p>Content true</p>\n"+
                  "Template", @plugin.render_node( file ) )
    assert_equal( nil, @plugin.render_node( file, 'other' ) )
    assert_equal( "<p>Content true</p>", @plugin.render_node( file, 'content', false ) )
  end

end
