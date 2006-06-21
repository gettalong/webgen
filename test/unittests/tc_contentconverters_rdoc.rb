require 'webgen/test'

class RDocConverterTest < Webgen::PluginTestCase

  plugin_files ['webgen/plugins/contentconverters/rdoc.rb']
  plugin_to_test 'ContentConverters::RDocConverter'

  def test_initialization
    assert_not_nil( @plugin )
  end

  def test_call
    assert_nothing_raised { @plugin.call( '* hello' ) }
  end

end
