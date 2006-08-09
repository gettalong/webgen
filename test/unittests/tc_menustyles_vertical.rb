require 'webgen/test'

class VerticalMenuStyleTest < Webgen::PluginTestCase

  plugin_files [
                'webgen/plugins/menustyles/vertical.rb',
                'webgen/plugins/filehandlers/directory.rb',
                'webgen/plugins/filehandlers/page.rb'
               ]

  plugin_to_test 'MenuStyles::VerticalMenuStyle'

  def test_submenu
    root = @manager['FileHandlers::FileHandler'].instance_eval { build_tree }
    flunk
  end

end
