require 'webgen/test'
require 'webgen/node'

class CustomVarTagTest < Webgen::TagTestCase

  plugin_files [
    'webgen/plugins/tags/customvar.rb'
  ]
  plugin_to_test 'Tag/CustomVar'


  def test_process_tag
    node = Node.new( nil, 'hallo.page' )

    @manager['Core/Configuration'].param('customVars').replace( {} )
    set_config( 'var' => 'test' )
    assert_equal( '', @plugin.process_tag( 'customVar', [node] ) )

    @manager['Core/Configuration'].param('customVars').replace( {'test' => 'value'} )
    set_config( 'var' => 'test' )
    assert_equal( 'value', @plugin.process_tag( 'customVar', [node] ) )
  end

end
