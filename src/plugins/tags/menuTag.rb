require 'ups/ups'
require 'node'
require 'plugins/tags/tags'

class MenuTag < UPS::Plugin

    NAME = 'Menu Tag'
    SHORT_DESC = 'Builds up a menu'

    def init
        UPS::Registry['Tags'].tags['menu'] = self
    end


	def process_tag( tag, content, node, templateNode )
        if !defined? @menuTree
            @menuTree = create_menu_tree( Node.root( node ), nil )
            UPS::Registry['Tree Transformer'].execute @menuTree unless @menuTree.nil?
        end
        build_menu( node, @menuTree, content['level'] )
	end

    #######
    private
    #######

    def build_menu( srcNode, node, level )
        return '' unless level >= 1

        out = '<ul>'
        node.each do |child|
            if child.kind_of? MenuNode
                submenu = child['isDir'] ? build_menu( srcNode, child, level - 1 ) : ''
                before, after = menu_entry( srcNode, child['node']['processor'].get_lang_node( child['node'], srcNode['lang'] ), child['isDir'] )
            else
                submenu = ''
                before, after = menu_entry( srcNode, child['processor'].get_lang_node( child, srcNode['lang'] ) )
            end

            out << before
            out << submenu
            out << after
        end
        out << '</ul>'

        return out
    end


    def menu_entry( srcNode, node, isDir = false )
        url = UPS::Registry['Tree Utils'].get_relpath_to_node( srcNode, node ) + node['dest']

        styles = []
        styles << 'submenu' if isDir
        styles << 'selectedMenu' if !isDir && node.recursive_value( 'dest' ) == srcNode.recursive_value( 'dest' )

        title = isDir ? node['directoryName'] : node['title']

        style = " class=\"#{styles.join(',')}\"" if styles.length > 0
        link = "<a href=\"#{url}\">#{title}</a>"

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


    class MenuNode < Node

        def initialize( node, parent )
            super parent
            self['title'] = 'Menu: '+ node['title']
            self['isMenuNode'] = true
            self['virtual'] = true
            self['isDir'] = node.kind_of? DirNode
            self['node'] = node
        end

    end


    def create_menu_tree( node, parent )
        menuNode = MenuNode.new( node, parent)

        node.each do |child|
            menu = create_menu_tree( child, menuNode )
            menuNode.add_child menu unless menu.nil?
        end

        return menuNode.has_children? ? menuNode : (put_node_in_menu?( node ) ? node : nil )
    end


    def put_node_in_menu?( node )
        inMenu = node['inMenu']
        inMenu ||=  node.parent && node.parent['pagePlugin:basename'] &&
                    node.parent.find do |child| child['inMenu'] end
        inMenu &&= !node['virtual']
        inMenu
    end

end

UPS::Registry.register_plugin MenuTag
