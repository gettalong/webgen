require 'webgen/test'
require 'webgen/node'
require 'webgen/content'

module ContentProcessorTests

  class BlocksTest < Webgen::PluginTestCase

    plugin_to_test 'ContentProcessor/Blocks'

    def test_process
      node = Node.new( nil, 'test' )
      node.node_info[:page] = WebPageFormat.create_page_from_data( "--- content\ndata" )
      template = Node.new( nil, 'template' )
      template.node_info[:page] = WebPageFormat.create_page_from_data( "--- content, pipeline:blocks\nbefore<webgen:block name='content' />after" )
      processors = { 'blocks' => @plugin }

      context = Context.new( processors, [node] )
      context.content = '<webgen:block name="content" />'
      @plugin.process( context )
      assert_equal( 'data', context.content )
      assert_equal( [node.absolute_lcn], context.cache_info[@plugin.plugin_name])

      context.content = '<webgen:block name="nothing"/>'
      assert_raise( RuntimeError ) { @plugin.process( context) }

      context.content = '<webgen:block name="content" />'
      context.cache_info = {}
      context.chain = [node, template, node]
      @plugin.process( context )
      assert_equal( 'beforedataafter', context.content )
      assert_equal( [template.absolute_lcn, node.absolute_lcn], context.cache_info[@plugin.plugin_name])
    end

  end

end
