require 'ups/ups'
require 'plugins/tags/tags'

class MenuTag < UPS::Plugin

    NAME = 'Menu Tag'
    SHORT_DESC = 'Builds up a menu'

    def init
        UPS::Registry['Tags'].tags['menu'] = self
    end

	def process_tag( tag, content, node, templateNode )
        build_menu( node, Node.root( node ), content['level'] )
	end


    def build_menu( srcNode, node, level )
        out = ''
        node.each do |child|
            menu = build_menu( srcNode, child, level - 1 ) unless level <= 1 || !node.has_children?
            if menu != '' || child['inMenu']
                before, after = menu_entry( srcNode, child )
                out << before
                out << menu
                out << after
            end
        end

        out = '<ul>' + out + '</ul>' if out != ''

        return out
    end


    def menu_entry( srcNode, node )
        url = UPS::Registry['Tree Utils'].get_relpath_to_node( srcNode, node ) + node['dest']

        styles = []
        styles << 'submenu' if node.children && node.children.length > 0
        styles << 'selectedMenu' if node.recursive_value( 'dest' ) == srcNode.recursive_value( 'dest' )

        style = " class=\"#{styles.join(',')}\"" if styles.length > 0
        link = "<a href=\"#{url}\">#{node['title']}</a>"

        if styles.include? 'submenu'
            before = "<li#{style}>#{link}"
            after = "</li>"
        else
            before = "<li#{style}>#{link}</li>"
            after = ""
        end

        Log4r::Logger['plugin'].debug { [before, after] }
        return before, after
    end

end

UPS::Registry.register_plugin MenuTag
