require 'ups/ups'
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
            if child['isDir']
                menu = build_menu( srcNode, child, level - 1 )
                before, after = menu_entry( srcNode, child['node'] )
            else
                menu = ''
                before, after = menu_entry( srcNode, get_correct_lang_node( child, srcNode ) )
            end

            out << before
            out << menu
            out << after
        end
        out << '</ul>'

        return out
    end


    def get_correct_lang_node( node, srcNode )
        langNode = node.find do |child| child['lang'] == srcNode['lang'] end
        langNode = node.find do |child| child['lang'] == UPS::Registry['Configuration'].lang end if langNode.nil?
        langNode
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


    def create_menu_tree( node, parent )
        treeNode = Node.new parent
        treeNode['title'] = 'Menu: '+ node['title']
        treeNode['isMenuNode'] = treeNode['virtual'] = true
        treeNode['isDir'] = node.kind_of? DirNode
        treeNode['node'] = node

        useNode = node['inMenu'] && !node['virtual']

        node.each do |child|
            menu = create_menu_tree( child, treeNode )
            treeNode.add_child menu unless menu.nil?
        end

        return treeNode.has_children? ? treeNode : (useNode ? node : nil )
    end


end

UPS::Registry.register_plugin MenuTag
