require 'webgen/test'
require 'webgen/node'
require 'webgen/content'

module ContentProcessorTests

  class BlocksTest < Webgen::PluginTestCase

    plugin_to_test 'ContentProcessor/Blocks'

    def test_process
      root = Node.new( nil, 'root' )
      node = Node.new( root, 'test' )
      node.node_info[:page] = WebPageFormat.create_page_from_data( "--- content\ndata" )
      template = Node.new( root, 'template' )
      template.node_info[:page] = WebPageFormat.create_page_from_data( "--- content, pipeline:blocks\nbefore<webgen:block name='content' />after" )
      processors = { 'blocks' => @plugin }

      context = Context.new( processors, [node] )
      context.content = '<webgen:block name="content" /><webgen:block name="content" chain="template;test" />'
      @plugin.process( context )
      assert_equal( 'databeforedataafter', context.content )
      assert_equal( [node.absolute_lcn, template.absolute_lcn, node.absolute_lcn], context.cache_info[@plugin.plugin_name])

      context.content = '<webgen:block name="nothing"/>'
      assert_raise( RuntimeError ) { @plugin.process( context) }

      context.content = '<webgen:block name="content" chain="invalid" /><webgen:block name="content" />'
      context.cache_info = {}
      context.chain = [node, template, node]
      @plugin.process( context )
      assert_equal( '<webgen:block name="content" chain="invalid" />beforedataafter', context.content )
      assert_equal( [template.absolute_lcn, node.absolute_lcn], context.cache_info[@plugin.plugin_name])
    end

  end

end
