module NodeProcessor

    def create_node( path, parent )
        raise "Not implemented"
    end

    def write_node( node )
        raise "Not implemented"
	end

    def get_lang_node( node, lang = node['lang'] )
        node
    end

    def get_html_link( node, refNode, title = node['title'] )
        url = UPS::Registry['Tree Utils'].get_relpath_to_node( refNode, node ) + node['dest']
        "<a href=\"#{url}\">#{title}</a>"
    end

end

