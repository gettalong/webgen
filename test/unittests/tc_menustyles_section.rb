require 'webgen/test'

class SectionMenuStyleTest < Webgen::PluginTestCase

  plugin_files [
                'webgen/plugins/menustyles/section.rb',
                'webgen/plugins/filehandlers/directory.rb',
                'webgen/plugins/filehandlers/page.rb',
                'webgen/plugins/coreplugins/resourcemanager.rb'
               ]

  plugin_to_test 'MenuStyles::SectionMenuStyle'

  def test_submenu
    root = @manager['FileHandlers::FileHandler'].instance_eval { build_tree }
    node = root.resolve_node( 'file1.page' )
    #puts @plugin.instance_eval { internal_build_menu( node, nil ) }
    flunk
  end

end
