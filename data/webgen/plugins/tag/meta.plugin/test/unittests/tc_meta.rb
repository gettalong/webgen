require 'webgen/test'
require 'webgen/node'

class MetaTest < Webgen::PluginTestCase

  plugin_to_test 'Tag/Meta'

  def test_process_tag
    node = Node.new( nil, 'hallo.page' )
    node['test'] = 10
    c = Context.new( {}, [node] )
    assert_equal( '', @plugin.process_tag( 'invalid', '', c ) )
    assert_equal( '10', @plugin.process_tag( 'test', '', c ) )
  end

end
