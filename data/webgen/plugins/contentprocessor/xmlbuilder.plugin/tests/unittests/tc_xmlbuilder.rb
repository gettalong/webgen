require 'webgen/test'

class XmlBuilderConverterTest < Webgen::PluginTestCase

  plugin_to_test 'ContentProcessor/XmlBuilder'

  def test_initialization
    assert_not_nil( @plugin )
  end

  def test_process
    context = Context.new( {}, [])
    context.content = "xml.div { xml.strong('test') }"
    assert_equal( "<div>\n  <strong>test</strong>\n</div>\n", @plugin.process( context ).content )
  end

end
