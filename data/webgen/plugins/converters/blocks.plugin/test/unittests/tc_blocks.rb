require 'webgen/test'
require 'webgen/node'
require 'webgen/content'

module ContentProcessorTests

  class BlocksTest < Webgen::PluginTestCase

    plugin_to_test 'ContentProcessor/Blocks'

    def test_process
      node = Node.new( nil, 'test' )
      node.node_info[:page] = Page.create_from_data( "--- content\ndata" )
      template = Node.new( nil, 'template' )
      template.node_info[:page] = Page.create_from_data( "--- content, pipeline:blocks\nbefore<webgen:block name='content' />after" )
      processors = { 'blocks' => @plugin }

      assert_equal( 'data', @plugin.process('<webgen:block name="content" />', {:chain=>[node]}, {}))
      assert_equal( '<webgen:block name="nothing"/>', @plugin.process('<webgen:block name="nothing"/>', {:chain=>[node]}, {}))
      assert_equal( 'beforedataafter', @plugin.process('<webgen:block name="content" />', 
                                                       {:chain=>[node, template, node], :processors => processors}, {}))
    end

  end

end
