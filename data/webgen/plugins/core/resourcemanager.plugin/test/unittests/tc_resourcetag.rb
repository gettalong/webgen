require 'webgen/test'

class ResourceTagTest < Webgen::PluginTestCase

  plugin_to_test 'Tag/Resource'

  def test_process_tag
    css = @manager['Core/ResourceManager'].get_resource( 'webgen/memory/css' )
    node = Node.new( nil, 'out' )

    @plugin.set_params( 'name' => 'webgen/memory/css', 'insert' => :path )
    assert_equal( ["{relocatable: css/webgen.css}", true], @plugin.process_tag( 'resource', '', Context.new( {}, [node] ) ) )

    css['data'] << 'testdata'
    @plugin.set_params( 'name' => 'webgen/memory/css', 'insert' => :data )
    assert_equal( ['testdata', false], @plugin.process_tag( 'resource', '', Context.new( {}, [node] ) ) )
  end

end
