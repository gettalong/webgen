require 'webgen/test'

class DefaultMenuStyleTest < Webgen::PluginTestCase

  plugin_files [
                'webgen/plugins/menustyles/default.rb',
                'webgen/plugins/filehandlers/directory.rb',
                'webgen/plugins/filehandlers/page.rb'
               ]

  plugin_to_test 'MenuStyle/Default'

  def test_menu_item_details
    root = @manager['Core/FileHandler'].instance_eval { build_tree }

    src_node = root.resolve_node( 'dir1/dir11/file111.en.page' )
    csub  = @plugin.param( 'submenuClass' )
    chier = @plugin.param( 'submenuInHierarchyClass' )
    csel  = @plugin.param( 'selectedMenuitemClass' )

    assert_equal( ["class=\"#{csub} #{chier}\"", root.link_from( src_node )],
                  @plugin.instance_eval { menu_item_details( src_node, root ) } )

    node = root.resolve_node( 'file1.en.page' )
    assert_equal( [nil, node.link_from( src_node )],
                  @plugin.instance_eval { menu_item_details( src_node, node ) } )

    node = root.resolve_node( 'dir1' )
    assert_equal( ["class=\"#{csub} #{chier}\"", node.link_from( src_node )],
                  @plugin.instance_eval { menu_item_details( src_node, node ) } )

    node = root.resolve_node( 'dir1/dir11/file111.en.page' )
    assert_equal( ["class=\"#{csel}\"", node.link_from( src_node )],
                  @plugin.instance_eval { menu_item_details( src_node, node ) } )
  end

end
