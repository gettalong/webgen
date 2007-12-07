module FileHandlers

  class PageFragmentHandler < DefaultHandler

    def init_plugin
      @plugin_manager['Core/FileHandler'].add_msg_listener( :after_node_created, &method(:handle_page_node) )
    end

    def handle_page_node( node )
      sections = @plugin_manager['Core/CacheManager'].get( [:nodes, node.absolute_lcn, :fragments, 'content'] )
      if sections
        inMenu = (node.meta_info.has_key?( 'fragmentsInMenu' ) ? node['fragmentsInMenu'] : param( 'fragmentsInMenu' ))
        create_fragment_nodes( sections, node, inMenu )
      end
    end

    def create_fragment_nodes( sections, parent, inMenu, oi = 1000 )
      sections.each do |s|
        n = Node.new( parent, '#' + s[1] )
        n['title'] = s[2]
        n['inMenu'] = inMenu
        n['orderInfo'] = oi = oi.succ
        n.node_info[:processor] = self
        create_fragment_nodes( s[3], n, inMenu, oi.succ )
      end
    end

  end

end
