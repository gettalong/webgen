module Tag

  class VerticalMenu < MenuBaseTag

    def build_menu( src_node, menu_tree )
      output, used_node_infos = submenu( src_node, menu_tree, 1 )
      ["<div class=\"webgen-menu-vert #{param('divClass')}\">#{output}</div>", {:node_infos => used_node_infos}]
    end

    def submenu( src_node, menu_node, level )
      if menu_node.nil? \
        || level > param( 'maxLevels' ) + param( 'startLevel' ) - 1 \
        || ( ( level > param( 'minLevels' ) + param( 'startLevel' ) - 1 ) \
             && ( menu_node.level >= src_node.level \
                  || ( param( 'showCurrentSubtreeOnly' ) && !src_node.in_subtree_of?( menu_node.node_info[:node] ) )
                  )
             ) \
        || src_node.level < param( 'startLevel' ) \
        || (level == param('startLevel') && !src_node.in_subtree_of?( menu_node.node_info[:node] ))
        return ''
      end

      used_node_infos = []
      sub_node_infos = []
      submenus = ''
      out = "<ul>"
      menu_node.each do |child|
        menu, tmp_nodes = child.has_children? ? submenu( src_node, child, level + 1 ) : ['', nil]
        style, link = menu_item_details( src_node, child.node_info[:node] )
        used_node_infos << child.node_info[:node]
        used_node_infos += tmp_nodes if tmp_nodes

        sub_node_infos += tmp_nodes if tmp_nodes
        submenus << menu
        out << "<li #{style}>#{link}"
        out << menu
        out << "</li>"
      end
      out << "</ul>"

      if level < param( 'startLevel' )
        ['' + submenus, sub_node_infos]
      else
        [out, used_node_infos]
      end
    end

  end

end
