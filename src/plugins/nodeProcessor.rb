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

end

