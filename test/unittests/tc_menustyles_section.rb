require 'webgen/test'

class SectionMenuStyleTest < Webgen::PluginTestCase

  plugin_files [
                'webgen/plugins/menustyles/section.rb',
                'webgen/plugins/filehandlers/directory.rb',
                'webgen/plugins/filehandlers/page.rb',
                'webgen/plugins/coreplugins/resourcemanager.rb'
               ]

  plugin_to_test 'MenuStyle/Section'

  def test_submenu
    root = @manager['Core/FileHandler'].instance_eval { build_tree }
    node = root.resolve_node( 'file1.page' )

    output = @plugin.build_menu( node, nil, {'maxLevels'=>3, 'numberSections'=>true} )
    assert_equal( menu_output( '<ul><li><a href="#test">1. Test 1</a>' +
                               '<ul><li><a href="#test11">1.1. Test - 1</a></li>' +
                               '<li><a href="#test12">1.2. Test - 2</a>' +
                               '<ul><li><a href="#test121">1.2.1. Test - - 1</a></li>' +
                               '<li><a href="#test122">1.2.2. Test - - 2</a></li></ul></li>' +
                               '<li><a href="#test13">1.3. Test - 3</a></li></ul></li>' +
                               '<li><a href="#test2">2. Test 2</a>' +
                               '<ul><li><a href="#test21">2.1. Test - 1</a></li></ul></li></ul>' ), output )

    output = @plugin.build_menu( node, nil, {'maxLevels'=>3, 'numberSections'=>false} )
    assert_equal( menu_output( '<ul><li><a href="#test">Test 1</a>' +
                               '<ul><li><a href="#test11">Test - 1</a></li>' +
                               '<li><a href="#test12">Test - 2</a>' +
                               '<ul><li><a href="#test121">Test - - 1</a></li>' +
                               '<li><a href="#test122">Test - - 2</a></li></ul></li>' +
                               '<li><a href="#test13">Test - 3</a></li></ul></li>' +
                               '<li><a href="#test2">Test 2</a>' +
                               '<ul><li><a href="#test21">Test - 1</a></li></ul></li></ul>' ), output )

    output = @plugin.build_menu( node, nil, {'maxLevels'=>2, 'numberSections'=>false} )
    assert_equal( menu_output( '<ul><li><a href="#test">Test 1</a>' +
                               '<ul><li><a href="#test11">Test - 1</a></li>' +
                               '<li><a href="#test12">Test - 2</a></li>' +
                               '<li><a href="#test13">Test - 3</a></li></ul></li>' +
                               '<li><a href="#test2">Test 2</a>' +
                               '<ul><li><a href="#test21">Test - 1</a></li></ul></li></ul>' ), output )

    output = @plugin.build_menu( node, nil, {'maxLevels'=>1, 'numberSections'=>true} )
    assert_equal( menu_output( '<ul><li><a href="#test">1. Test 1</a></li>' +
                               '<li><a href="#test2">2. Test 2</a></li></ul>' ), output )
  end

  #######
  private
  #######

  def menu_output( menu )
    '<div class="webgen-menu-section webgen-menu">' + menu + '</div>'
  end

end
