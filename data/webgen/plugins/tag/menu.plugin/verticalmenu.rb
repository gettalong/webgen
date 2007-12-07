module Tag

  class VerticalMenu < MenuBaseTag

    def build_menu( tag, body, context, menu_tree )
      tree = build_param_specific_menu_tree( context.node, menu_tree )
      (context.cache_info[plugin_name] ||= []) << [all_params, (tree ? tree.to_lcn_list : nil)]
      if tree && !tree.children.empty?
        "<div class=\"webgen-menu-vert #{param('divClass')}\">#{create_output(context.node, tree)}</div>"
      else
        ""
      end
    end

    def build_param_specific_menu_tree( src_node, menu_tree )
      if param('useTypes') == 'fragments' && (menu_tree = get_fragments_only_menu_tree( src_node, menu_tree ))
        menu_tree, temp = MenuNode.new( nil, menu_tree.node_info[:node] ), menu_tree
        menu_tree.add_children( temp.children )
      end
      internal_build_menu_tree( src_node, menu_tree, 1 )
    end

    def get_fragments_only_menu_tree( node, menu_tree )
      chain = []
      (chain.unshift( node ); node = node.parent) while !node.parent.nil?
      chain.each do |node|
        menu_tree = menu_tree.find {|mn| mn.node_info[:node] == node}
        break if menu_tree.nil?
      end
      menu_tree
    end

    def internal_build_menu_tree( src_node, menu_node, level )
      if menu_node.nil? \
        || level > param( 'maxLevels' ) + param( 'startLevel' ) - 1 \
        || ( ( level > param( 'minLevels' ) + param( 'startLevel' ) - 1 ) \
             && ( menu_node.level >= src_node.level \
                  || ( param( 'showCurrentSubtreeOnly' ) && !src_node.in_subtree_of?( menu_node.node_info[:node] ) )
                  )
             ) \
        || (level == param('startLevel') && !src_node.in_subtree_of?( menu_node.node_info[:node] ))
        return nil
      end

      sub_menu_tree = MenuNode.new( nil, menu_node.node_info[:node] )
      menu_tree = MenuNode.new( nil, menu_node.node_info[:node] )
      menu_node.each do |child|
        next if (param('useTypes') == 'normal' && child.node_info[:node].is_fragment?)
        this_node = MenuNode.new( menu_tree, child.node_info[:node] )
        sub_node = child.has_children? ? internal_build_menu_tree( src_node, child, level + 1 ) : nil
        sub_node.each {|n| this_node.add_child(n); sub_menu_tree.add_child( n ) } if sub_node
        menu_tree.add_child( this_node )
      end

      if level < param( 'startLevel' )
        sub_menu_tree
      else
        menu_tree
      end
    end

    def create_output( src_node, tree )
      out = "<ul>"
      tree.each do |child|
        menu = child.has_children? ? create_output( src_node, child ) : ''
        style, link = menu_item_details( src_node, child.node_info[:node] )

        out << "<li #{style}>#{link}"
        out << menu
        out << "</li>"
      end
      out << "</ul>"
      out
    end

    def cache_info_changed?( data, node )

      def tree_changed?( tree, lang )
        tree.any? do |child|
          tree_changed?( child, lang ) || @plugin_manager['Core/FileHandler'].meta_info_changed?( child.node_info[:node].node_for_lang( lang ) )
        end
      end

      menu_tree = @plugin_manager['Tag/MenuBaseTag'].menu_tree_for_lang( node['lang'], Node.root( node ) )
      changed = false
      data.each do |params, list|
        set_params( params )
        tree = build_param_specific_menu_tree( node, menu_tree )
        set_params( nil )
        changed = (tree.nil? && !list.nil?) || (tree && tree_changed?( tree, node['lang'] )) ||
          (tree && tree.to_lcn_list != list)
        break if changed
      end
      changed
    end

  end

end
