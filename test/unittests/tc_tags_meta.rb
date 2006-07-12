require 'webgen/test'
require 'webgen/node'

class MetaTagTest < Webgen::TagTestCase

  plugin_files [
    'webgen/plugins/tags/meta.rb',
  ]
  plugin_to_test 'Tags::MetaTag'


  def test_process_tag
    node = Node.new( nil, 'hallo.page' )
    node.meta_info['test'] = 10
    assert_equal( '', @plugin.process_tag( 'invalid', [node] ) )
    assert_equal( '10', @plugin.process_tag( 'test', [node] ) )
  end

end
