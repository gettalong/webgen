require 'ups/ups'
require 'plugins/tags/tags'

class MenuTag < UPS::Plugin

    NAME = 'Menu Tag'
    SHORT_DESC = 'Builds up a menu'

    def init
        UPS::Registry['Tags'].tags['menu'] = self
    end

	def process_tag( tag, content, node, templateNode )
        #build_menu( node, Node.root( node ), content['level'] )
        if !defined? @menuTree
            @menuTree = create_menu_tree( Node.root( node ), nil, content['level'] )
            UPS::Registry['Tree Transformer'].execute @menuTree unless @menuTree.nil?
        end
        ''
	end

    def create_menu_tree( node, parent, level )
        treeNode = Node.new parent
        treeNode['title'] = 'Menu: '+ node['title']
        treeNode['isMenuNode'] = true
        treeNode['virtual'] = true

        added = node['inMenu'] && !node['virtual']

        node.each do |child|
            menu = create_menu_tree( child, treeNode, (child['virtual'] ? level : level - 1) )
            treeNode.add_child menu unless menu.nil?
        end

        return treeNode.has_children? ? treeNode : (added ? node : nil )
    end


    def build_menu( srcNode, node, level )
        return unless level >= 1

        out = ''
        node.each do |child|
            menu = (build_menu( srcNode, child, level - 1 ) if level > 1 && child.has_children?) || ''
            if (child['inMenu'] || menu != '')
                if child['lang'] == srcNode['lang']
                    usedNode = child
                else
                    usedNode = UPS::Registry['Language Tag'].get_other_lang_nodes( child, [UPS::Registry['Configuration'].defaultLang] )[0]
                end
                before, after = menu_entry( srcNode, usedNode )
            else
                before, after = ['', '']
            end

            out << before
            out << menu
            out << after
        end

        out = '<ul>' + out + '</ul>' unless out == ''

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

        self.logger.debug { [before, after] }
        return before, after
    end

end

UPS::Registry.register_plugin MenuTag
