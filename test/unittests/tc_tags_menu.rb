require 'webgen/test'
require 'webgen/node'

class MenuTagTest < Webgen::TagTestCase

  plugin_files [
    'webgen/plugins/tags/menu.rb',
    'webgen/plugins/filehandlers/directory.rb',
    'webgen/plugins/filehandlers/page.rb',
  ]
  plugin_to_test 'Tag/Menu'


  def test_create_menu_tree
    root = @manager['Core/FileHandler'].instance_eval { build_tree }

    tree_en = @plugin.instance_eval { create_menu_tree( root, nil, Webgen::LanguageManager.language_for_code( 'en' ) ) }
    nodes = [
             root,
             root.resolve_node( 'dir1' ),
             root.resolve_node( 'dir1/dir11' ),
             root.resolve_node( 'dir1/dir11/file111.en.page' ),
             root.resolve_node( 'dir1/dir11/index.page' ),
             root.resolve_node( 'dir1/file11.page' ),
             root.resolve_node( 'dir2' ),
             root.resolve_node( 'dir2/file21.page' )
            ]

    check_tree( tree_en, nodes )
    assert( nodes.empty? )


    tree_de = @plugin.instance_eval { create_menu_tree( root, nil, Webgen::LanguageManager.language_for_code( 'de' ) ) }
    nodes = [
             root,
             root.resolve_node( 'dir1' ),
             root.resolve_node( 'dir1/dir11' ),
             root.resolve_node( 'dir1/dir11/file111.de.page' ),
             root.resolve_node( 'file2.de.page' )
            ]
    check_tree( tree_de, nodes )
    assert( nodes.empty? )
  end

  def check_tree( tree, nodes )
    assert_same( nodes.shift, tree.node_info[:node] )
    tree.each {|c| check_tree( c, nodes )}
  end

end
