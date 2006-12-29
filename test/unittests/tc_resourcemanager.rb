require 'webgen/test'
require 'webgen/node'

class ResourceManagerTest < Webgen::PluginTestCase

  plugin_files ['webgen/plugins/coreplugins/resourcemanager.rb']

  plugin_to_test 'Core/ResourceManager'

  def test_get_resource
    assert_not_nil( @plugin.get_resource( 'webgen-css' ) )
    assert_not_nil( @plugin.get_resource( 'webgen-javascript' ) )
  end

  def test_append_data
    data = 'testdata'
    @plugin.append_data( 'webgen-css', data )
    assert_equal( data, @plugin.get_resource( 'webgen-css' ).data )
    @plugin.append_data( 'invalid-resource', data )
  end

end

class ResourceTagTest < Webgen::TagTestCase

  plugin_files ['webgen/plugins/coreplugins/resourcemanager.rb']

  plugin_to_test 'Tag/Resource'

  def test_process_tag
    css = @manager['Core/ResourceManager'].get_resource( 'webgen-css' )
    node = Node.new( nil, 'out' )

    set_config( 'name' => 'webgen-css', 'insert' => :path )
    assert_equal( css.output_path, @plugin.process_tag( 'resource', [node] ) )

    css.append_data( 'testdata' )
    set_config( 'name' => 'webgen-css', 'insert' => :data )
    assert_equal( 'testdata', @plugin.process_tag( 'resource', [node] ) )
  end

end
