require 'webgen/test'

class XmllintHtmlValidatorTest < Webgen::PluginTestCase

  plugin_files ['webgen/plugins/htmlvalidators/xmllint.rb']
  plugin_to_test 'HtmlValidator/xmllint'


  def test_loading_of_plugin
    assert_not_nil( @plugin )
  end

  def test_validate_file
    assert_nothing_raised do
      assert( !@plugin.validate_file( 'invalid' ) )
    end
  end

end
