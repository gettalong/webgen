require 'webgen/test'

class VerticalMenuStyleTest < Webgen::PluginTestCase

  plugin_files [
                'webgen/plugins/menustyles/vertical.rb',
                'webgen/plugins/filehandlers/directory.rb',
                'webgen/plugins/filehandlers/page.rb',
                'webgen/plugins/tags/menu.rb'
               ]

  plugin_to_test 'MenuStyle/Vertical'

  def test_submenu
    root = @manager['Core/FileHandler'].instance_eval { build_tree }
    tree_en = @manager['Tags/MenuTag'].instance_eval { create_menu_tree( root, nil, Webgen::LanguageManager.language_for_code( 'en' ) ) }

    # testing minLevels and maxLevels
    output = @plugin.build_menu( root.resolve_node('index.en.page'), tree_en, options_hash( 1, 1, 1, true ) )
    assert_equal( menu_output( '<ul><li class="webgen-menu-submenu"><a href="dir1/">Dir1</a></li>' +
                               '<li class="webgen-menu-submenu"><a href="dir2/">Dir2</a></li></ul>' ), output )
    output = @plugin.build_menu( root.resolve_node('index.en.page'), tree_en, options_hash( 1, 2, 1, true ) )
    assert_equal( menu_output( '<ul><li class="webgen-menu-submenu"><a href="dir1/">Dir1</a></li>' +
                               '<li class="webgen-menu-submenu"><a href="dir2/">Dir2</a></li></ul>' ), output )
    output = @plugin.build_menu( root.resolve_node('index.en.page'), tree_en, options_hash( 1, 2, 2, true ) )
    assert_equal( menu_output( '<ul><li class="webgen-menu-submenu"><a href="dir1/">Dir1</a>'+
                               '<ul><li class="webgen-menu-submenu"><a href="dir1/dir11/index.html">Dir11</a></li>'+
                               '<li ><a href="dir1/file11.html">File11</a></li></ul></li>' +
                               '<li class="webgen-menu-submenu"><a href="dir2/">Dir2</a>'+
                               '<ul><li ><a href="dir2/file21.html">File21</a></li></ul></li></ul>' ), output )
    output = @plugin.build_menu( root.resolve_node('index.en.page'), tree_en, options_hash( 2, 1, 1, true ) )
    assert_equal( menu_output( '' ), output )

    # testing showCurrentSubtreeOnly
    output = @plugin.build_menu( root.resolve_node('dir1/file11.en.page'), tree_en, options_hash( 1, 1, 2, true ) )
    assert_equal( menu_output( '<ul><li class="webgen-menu-submenu webgen-menu-submenu-inhierarchy"><a href="./">Dir1</a>'+
                               '<ul><li class="webgen-menu-submenu"><a href="dir11/index.html">Dir11</a></li>'+
                               '<li class="webgen-menu-item-selected"><a href="file11.html">File11</a></li></ul></li>' +
                               '<li class="webgen-menu-submenu"><a href="../dir2/">Dir2</a></li></ul>' ), output )
    output = @plugin.build_menu( root.resolve_node('dir1/file11.en.page'), tree_en, options_hash( 1, 1, 2, false ) )
    assert_equal( menu_output( '<ul><li class="webgen-menu-submenu webgen-menu-submenu-inhierarchy"><a href="./">Dir1</a>'+
                               '<ul><li class="webgen-menu-submenu"><a href="dir11/index.html">Dir11</a></li>'+
                               '<li class="webgen-menu-item-selected"><a href="file11.html">File11</a></li></ul></li>' +
                               '<li class="webgen-menu-submenu"><a href="../dir2/">Dir2</a>'+
                               '<ul><li ><a href="../dir2/file21.html">File21</a></li></ul></li></ul>' ), output )

    # testing startLevel
    output = @plugin.build_menu( root.resolve_node('dir1/file11.en.page'), tree_en, options_hash( 2, 1, 2, true ) )
    assert_equal( menu_output( '<ul><li class="webgen-menu-submenu"><a href="dir11/index.html">Dir11</a></li>'+
                               '<li class="webgen-menu-item-selected"><a href="file11.html">File11</a></li></ul>' ), output )
    output = @plugin.build_menu( root.resolve_node('dir1/file11.en.page'), tree_en, options_hash( 2, 1, 2, false ) )
    assert_equal( menu_output( '<ul><li class="webgen-menu-submenu"><a href="dir11/index.html">Dir11</a></li>'+
                               '<li class="webgen-menu-item-selected"><a href="file11.html">File11</a></li></ul>' ), output )
    output = @plugin.build_menu( root.resolve_node('dir1/file11.en.page'), tree_en, options_hash( 2, 2, 2, false ) )
    assert_equal( menu_output( '<ul><li class="webgen-menu-submenu"><a href="dir11/index.html">Dir11</a>' +
                               '<ul><li ><a href="dir11/file111.html">File111</a></li>' +
                               '<li ><a href="dir11/index.html">Index</a></li></ul></li>'+
                               '<li class="webgen-menu-item-selected"><a href="file11.html">File11</a></li></ul>' ), output )
    output = @plugin.build_menu( root.resolve_node('dir1/dir11/file111.en.page'), tree_en, options_hash( 2, 1, 2, true ) )
    assert_equal( menu_output( '<ul><li class="webgen-menu-submenu webgen-menu-submenu-inhierarchy">' +
                               '<a href="index.html">Dir11</a>' +
                               '<ul><li class="webgen-menu-item-selected"><a href="file111.html">File111</a></li>'+
                               '<li ><a href="index.html">Index</a></li></ul></li>' +
                               '<li ><a href="../file11.html">File11</a></li></ul>' ), output )
  end

  #######
  private
  #######

  def options_hash( startLevel, minLevels, maxLevels, subtree )
    {'startLevel'=>startLevel, 'minLevels'=>minLevels, 'maxLevels'=>maxLevels, 'showCurrentSubtreeOnly'=>subtree}
  end

  def menu_output( menu )
    '<div class="webgen-menu-vert webgen-menu">' + menu + '</div>'
  end

end
