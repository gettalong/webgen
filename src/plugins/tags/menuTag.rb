require 'ups/ups'
require 'plugins/tags/tags'

class MenuTag < UPS::Plugin

    NAME = 'Menu Tag'
    SHORT_DESC = 'Builds up a menu'

    def init
        UPS::Registry['Tags'].tags['menu'] = self
    end

	def process_tag( tag, content, node, templateNode )
        root = node
        root = root.parent until root.parent.nil?
        build_menu( node, root, content['level'] )
	end


    def build_menu( srcNode, node, level )
        return '' if level == 0 || !node['processor'].kind_of?( DirHandlerPlugin )
        out = '<ul>'
        node.each do |child|
            out << menu_entry( srcNode, child ) if  child['processor'].kind_of?( PagePlugin ) || (level > 1 && child['processor'].kind_of?( DirHandlerPlugin ))
            out << build_menu( srcNode, child, level - 1 ) unless node.children.nil? || level == 1
        end
        out <<'</ul>'
        return out
    end


    def menu_entry( srcNode, node )
        url = UPS::Registry['Tree Utils'].get_relpath_to_node( srcNode, node ) + node['dest']

        style = node.children.nil? ? '' : 'submenu'
        style += node.recursive_value( 'dest' ) == srcNode.recursive_value( 'dest' ) ? (style != '' ? ',' : '') +'selectedMenu' : ""
        style = " class=\"#{style}\"" if style != ''

        out = "<li#{style}><a href=\"#{url}\">#{node['title']}</a></li>"
        Log4r::Logger['plugin'].debug out
        return out
    end

end

UPS::Registry.register_plugin MenuTag
