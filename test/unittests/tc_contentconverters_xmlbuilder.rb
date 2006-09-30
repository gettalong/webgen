require 'webgen/test'

begin
  require 'builder'

  class XmlBuilderConverterTest < Webgen::PluginTestCase

    plugin_files ['webgen/plugins/contentconverters/xmlbuilder.rb']
    plugin_to_test 'ContentConverter/XmlBuilder'

    def test_initialization
      assert_not_nil( @plugin )
    end

    def test_call
      assert_equal( "<div>\n  <strong>test</strong>\n</div>\n", @plugin.call( "xml.div { xml.strong('test') }" ) )
    end

  end

rescue LoadError
end
