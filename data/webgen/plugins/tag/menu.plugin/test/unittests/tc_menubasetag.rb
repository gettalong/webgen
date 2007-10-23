require 'webgen/test'
require 'webgen/node'

class MenuBaseTagTest < Webgen::PluginTestCase

  plugin_to_test 'Tag/MenuBaseTag'

  def test_create_menu_tree
    root = @manager['Core/FileHandler'].instance_eval { build_tree }
    tree_en = @plugin.instance_eval { create_menu_tree( root, nil, Webgen::LanguageManager.language_for_code( 'en' ) ).sort! }
    nodes = [
             root.resolve_node( 'dir1' ),
             root.resolve_node( 'dir1/dir11' ),
             root.resolve_node( 'dir1/dir11/file111.en.html' ),
             root.resolve_node( 'dir1/dir11/index.html' ),
             root.resolve_node( 'dir1/file11.html' ),
             root.resolve_node( 'dir2' ),
             root.resolve_node( 'dir2/file21.html' )
            ].collect {|n| n.absolute_lcn}

    assert_equal( nodes, tree_en.to_lcn_list.flatten)

    tree_de = @plugin.instance_eval { create_menu_tree( root, nil, Webgen::LanguageManager.language_for_code( 'de' ) ).sort! }
    nodes = [
             root.resolve_node( 'dir1' ),
             root.resolve_node( 'dir1/dir11' ),
             root.resolve_node( 'dir1/dir11/file111.de.html' ),
             root.resolve_node( 'file2.de.html' )
            ].collect {|n| n.absolute_lcn}

    assert_equal( nodes, tree_de.to_lcn_list.flatten)
  end

end
