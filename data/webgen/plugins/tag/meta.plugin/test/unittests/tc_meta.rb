require 'webgen/test'
require 'webgen/node'

class MetaTest < Webgen::TagTestCase

  plugin_to_test 'Tag/Meta'

  def test_process_tag
    node = Node.new( nil, 'hallo.page' )
    node['test'] = 10
    assert_equal( '', @plugin.process_tag( 'invalid', '', node, node ) )
    assert_equal( '10', @plugin.process_tag( 'test', '', node, node ) )
  end

end
