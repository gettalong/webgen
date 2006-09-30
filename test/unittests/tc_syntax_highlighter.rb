require 'webgen/test'
require 'webgen/node'

class SyntaxHighlighterTest < Webgen::PluginTestCase

  plugin_files [
                'webgen/plugins/coreplugins/resourcemanager.rb',
                'webgen/plugins/miscplugins/syntax_highlighter.rb'
               ]

  plugin_to_test 'Misc/SyntaxHighlighter'

  def test_available_languages
    if @manager.optional_part( 'syntax-highlighting' )[:loaded]
      assert( @wrapper::MiscPlugins::SyntaxHighlighter.available_languages.length > 0 )
    else
      assert_equal( [], @wrapper::MiscPlugins::SyntaxHighlighter.available_languages )
    end
  end

  def test_highlight
    if @manager.optional_part( 'syntax-highlighting' )[:loaded]
      assert_not_nil( 'TestData', @plugin.highlight( 'TestData', 'ruby' ) )
      assert_not_nil( 'TestData', @plugin.highlight( 'TestData', :ruby ) )
    else
      assert_equal( 'Testdata', @plugin.highlight( 'Testdata', 'ruby' ) )
    end
  end

end
