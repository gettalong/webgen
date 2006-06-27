require 'webgen/test'

class DefaultHtmlValidatorTest < Webgen::PluginTestCase

  plugin_files ['webgen/plugins/htmlvalidators/default.rb']

  def test_validate_file
    plugin = HtmlValidators::DefaultHtmlValidator.new( @manager )
    assert_raises( NotImplementedError ) { plugin.validate_file( '' ) }
  end

end
