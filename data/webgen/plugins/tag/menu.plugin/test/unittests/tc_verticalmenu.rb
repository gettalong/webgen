require 'webgen/test'

class VerticalMenuStyleTest < Webgen::PluginTestCase

  plugin_to_test 'Tag/VerticalMenu'

  def test_submenu
    root = @manager['Core/FileHandler'].instance_eval { build_tree }
    tree_en = @manager['Tag/MenuBaseTag'].instance_eval { menu_tree_for_lang( Webgen::LanguageManager.language_for_code( 'en' ), root ) }

    # testing minLevels and maxLevels and also checking resulting cache information
    output, context = build_menu( root.resolve_node('index.en.html'), tree_en, [1, 1, 1, true] )
    assert_equal( menu_output( '<ul><li class="webgen-menu-submenu"><a href="dir1/">Dir1</a></li>' +
                               '<li class="webgen-menu-submenu"><a href="dir2/">Dir2</a></li></ul>' ), output )
    assert_equal( [
                   root.resolve_node( 'dir1' ),
                   root.resolve_node( 'dir2' ),
                  ].collect {|n| n.absolute_lcn}, context.cache_info[@plugin.plugin_name].first[1].flatten )


    output, context = build_menu( root.resolve_node('index.en.html'), tree_en, [1, 2, 1, true] )
    assert_equal( menu_output( '<ul><li class="webgen-menu-submenu"><a href="dir1/">Dir1</a></li>' +
                               '<li class="webgen-menu-submenu"><a href="dir2/">Dir2</a></li></ul>' ), output )
    assert_equal( [
                   root.resolve_node( 'dir1' ),
                   root.resolve_node( 'dir2' ),
                  ].collect {|n| n.absolute_lcn}, context.cache_info[@plugin.plugin_name].first[1].flatten )


    output, context = build_menu( root.resolve_node('index.en.html'), tree_en, [1, 2, 2, true] )
    assert_equal( menu_output( '<ul><li class="webgen-menu-submenu"><a href="dir1/">Dir1</a>'+
                               '<ul><li class="webgen-menu-submenu"><a href="dir1/dir11/index.html">Dir11</a></li>'+
                               '<li ><a href="dir1/file11.html">File11</a></li></ul></li>' +
                               '<li class="webgen-menu-submenu"><a href="dir2/">Dir2</a>'+
                               '<ul><li ><a href="dir2/file21.html">File21</a></li></ul></li></ul>' ), output )
    assert_equal( [
                   root.resolve_node( 'dir1' ),
                   root.resolve_node( 'dir1/dir11' ),
                   root.resolve_node( 'dir1/file11.html' ),
                   root.resolve_node( 'dir2' ),
                   root.resolve_node( 'dir2/file21.html' )
                  ].collect {|n| n.absolute_lcn}, context.cache_info[@plugin.plugin_name].first[1].flatten )

    # testing showCurrentSubtreeOnly
    output, context = build_menu( root.resolve_node('dir1/file11.en.html'), tree_en, [1, 1, 2, true] )
    assert_equal( menu_output( '<ul><li class="webgen-menu-submenu webgen-menu-submenu-inhierarchy"><a href="./">Dir1</a>'+
                               '<ul><li class="webgen-menu-submenu"><a href="dir11/index.html">Dir11</a></li>'+
                               '<li class="webgen-menu-item-selected"><span>File11</span></li></ul></li>' +
                               '<li class="webgen-menu-submenu"><a href="../dir2/">Dir2</a></li></ul>' ), output )
    output, context = build_menu( root.resolve_node('dir1/file11.en.html'), tree_en, [1, 1, 2, false] )
    assert_equal( menu_output( '<ul><li class="webgen-menu-submenu webgen-menu-submenu-inhierarchy"><a href="./">Dir1</a>'+
                               '<ul><li class="webgen-menu-submenu"><a href="dir11/index.html">Dir11</a></li>'+
                               '<li class="webgen-menu-item-selected"><span>File11</span></li></ul></li>' +
                               '<li class="webgen-menu-submenu"><a href="../dir2/">Dir2</a>'+
                               '<ul><li ><a href="../dir2/file21.html">File21</a></li></ul></li></ul>' ), output )

    # testing startLevel
    output, context = build_menu( root.resolve_node('index.en.html'), tree_en, [2, 1, 1, true] )
    assert_equal( '', output )
    output, context = build_menu( root.resolve_node('dir1/file11.en.html'), tree_en, [2, 1, 2, true] )
    assert_equal( menu_output( '<ul><li class="webgen-menu-submenu"><a href="dir11/index.html">Dir11</a></li>'+
                               '<li class="webgen-menu-item-selected"><span>File11</span></li></ul>' ), output )
    output, context = build_menu( root.resolve_node('dir1/file11.en.html'), tree_en, [2, 1, 2, false] )
    assert_equal( menu_output( '<ul><li class="webgen-menu-submenu"><a href="dir11/index.html">Dir11</a></li>'+
                               '<li class="webgen-menu-item-selected"><span>File11</span></li></ul>' ), output )
    output, context = build_menu( root.resolve_node('dir1/file11.en.html'), tree_en, [2, 2, 2, false] )
    assert_equal( menu_output( '<ul><li class="webgen-menu-submenu"><a href="dir11/index.html">Dir11</a>' +
                               '<ul><li ><a href="dir11/file111.html">File111</a></li>' +
                               '<li ><a href="dir11/index.html">Index</a></li></ul></li>'+
                               '<li class="webgen-menu-item-selected"><span>File11</span></li></ul>' ), output )
    output, context = build_menu( root.resolve_node('dir1/dir11/file111.en.html'), tree_en, [2, 1, 2, true] )
    assert_equal( menu_output( '<ul><li class="webgen-menu-submenu webgen-menu-submenu-inhierarchy">' +
                               '<a href="index.html">Dir11</a>' +
                               '<ul><li class="webgen-menu-item-selected"><span>File111</span></li>'+
                               '<li ><a href="index.html">Index</a></li></ul></li>' +
                               '<li ><a href="../file11.html">File11</a></li></ul>' ), output )
  end

  #######
  private
  #######

  def build_menu( node, tree, options )
    @plugin.set_params( options_hash( *options ) )
    context = Context.new( {}, [node] )
    output = @plugin.build_menu( 'verticalMenu', '', context, tree )
    @plugin.set_params( {} )
    [output, context]
  end

  def options_hash( startLevel, minLevels, maxLevels, subtree )
    {'startLevel'=>startLevel, 'minLevels'=>minLevels, 'maxLevels'=>maxLevels, 'showCurrentSubtreeOnly'=>subtree}
  end

  def menu_output( menu )
    '<div class="webgen-menu-vert webgen-menu">' + menu + '</div>'
  end

end
