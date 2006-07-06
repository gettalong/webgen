require 'webgen/test'

begin
  require 'bluecloth'

  class MarkdownConverterTest < Webgen::PluginTestCase

    plugin_files ['webgen/plugins/contentconverters/markdown.rb']
    plugin_to_test 'ContentConverters::MarkdownConverter'

    def test_initialization
      assert_not_nil( @plugin )
    end

    def test_call
      assert_nothing_raised { @plugin.call( '* hello' ) }
    end

  end

rescue LoadError
end
