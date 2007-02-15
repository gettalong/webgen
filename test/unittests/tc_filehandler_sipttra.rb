require 'webgen/test'

class SipttraHandlerTest < Webgen::PluginTestCase

  plugin_files [
    'webgen/plugins/filehandlers/sipttra.rb',
    'webgen/plugins/filehandlers/directory.rb'
  ]
  plugin_to_test 'File/SipttraHandler'

  def test_initialization
    assert_not_nil( @plugin )
  end

  def test_create_node
    root = @manager['Core/FileHandler'].instance_eval { create_root_node }
    file = sample_site( File.join( Webgen::SRC_DIR, 'test.todo' ) )
    node = @manager['Core/FileHandler'].create_node( File.basename( file ), root, @plugin )

    assert_not_nil( node )
    assert_equal( 'test.html', node.path )
    assert_equal( file, node.node_info[:src] )
    assert_kind_of( Sipttra::Tracker, node.node_info[:sipttra] )
  end

end
