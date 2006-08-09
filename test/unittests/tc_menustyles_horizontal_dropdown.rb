require 'webgen/test'

class HorizontalDropdownMenuStyleTest < Webgen::PluginTestCase

  plugin_files [
                'webgen/plugins/menustyles/horizontal_dropdown.rb',
                'webgen/plugins/filehandlers/directory.rb',
                'webgen/plugins/filehandlers/page.rb'
               ]

  plugin_to_test 'MenuStyles::HorizontalDropdownMenuStyle'

  def test_submenu
    root = @manager['FileHandlers::FileHandler'].instance_eval { build_tree }
    flunk
  end

end
