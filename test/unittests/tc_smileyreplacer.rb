require 'webgen/test'
require 'webgen/node'

class SmileyReplacerTest < Webgen::PluginTestCase

  plugin_files [
                'webgen/plugins/coreplugins/resourcemanager.rb',
                'webgen/plugins/miscplugins/smileyreplacer.rb'
               ]

  plugin_to_test 'MiscPlugins::SmileyReplacer'

  def test_replace_smileys
    node = Node.new( nil, 'test' )
    assert_equal( ':-)', @plugin.instance_eval { replace_smileys( ':-)', node ) } )

    node['emoticonPack'] = 'invalid_pack'
    assert_equal( ':-)', @plugin.instance_eval { replace_smileys( ':-)', node ) } )

    node['emoticonPack'] = 'glass'
    assert_equal( "<img src=\"#{@manager['CorePlugins::ResourceManager'].get_resource( 'webgen-emoticons-glass-smile' ).output_path}\" alt=\"smiley :-)\" />",
                  @plugin.instance_eval { replace_smileys( ':-)', node ) } )
  end

end
