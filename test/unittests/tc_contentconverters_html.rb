require 'webgen/test'

class HtmlConverterTest < Webgen::PluginTestCase

  plugin_files ['webgen/plugins/contentconverters/html.rb']
  plugin_to_test 'ContentConverters::HtmlConverter'

  def test_initialization
    assert_not_nil( @plugin )
  end

  def test_call
    assert_equal( '<a href="">test</a>', @plugin.call( '<a href="">test</a>' ) )
  end

end
