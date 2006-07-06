require 'webgen/test'

begin
  require 'redcloth'

  class TextileConverterTest < Webgen::PluginTestCase

    plugin_files ['webgen/plugins/contentconverters/textile.rb']
    plugin_to_test 'ContentConverters::TextileConverter'

    def test_initialization
      assert_not_nil( @plugin )
    end

    def test_call
      assert_nothing_raised { @plugin.call( '* hello' ) }
    end

  end

rescue LoadError
end
