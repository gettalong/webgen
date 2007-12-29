require 'webgen/test'
require 'webgen/node'

class ResourceManagerTest < Webgen::PluginTestCase

  plugin_to_test 'Core/ResourceManager'

  def test_get_resource
    assert_not_nil( @plugin.get_resource( 'webgen/memory/css' ) )
    assert_not_nil( @plugin.get_resource( 'webgen/memory/js' ) )
    assert_nil( @plugin.get_resource( 'asdfasdfasdfasdfasdfasdfasdfasdf' ) )
  end

end

