require 'webgen/test'

class VerticalDropdownMenuStyleTest < Webgen::PluginTestCase

  plugin_files [
                'webgen/plugins/menustyles/vertical_dropdown.rb',
                'webgen/plugins/filehandlers/directory.rb',
                'webgen/plugins/filehandlers/page.rb'
               ]

  plugin_to_test 'MenuStyles::VerticalDropdownMenuStyle'

  def test_submenu
    root = @manager['Core/FileHandler'].instance_eval { build_tree }
    flunk
  end

end
