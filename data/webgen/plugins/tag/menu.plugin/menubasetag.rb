require 'webgen/node'

module Tag

  # This class serves as base class for menu tag plugins. A menu tag plugin is a specialized tag
  # plugin that generates a menu.
  #
  # = General
  #
  # This base class defines some parameters which can be used in derived classes like the name of
  # the CSS class used for the currently selected item. It also provides utility methods for derived
  # menu tag plugins:
  #
  # * #menu_item_details
  #
  # = Menu generation
  #
  # This tag plugin automatically generates a valid menu tree for the node passed in the context
  # variable of the #process method. The generated menu tree is language dependent which means that
  # for each language a separate menu tree is generated. The order in which the menu items are
  # listed can be controlled via the meta information +orderInfo+.
  #
  # = Sample Menu Tag Plugin
  #
  # The reference implementation for a menu tag is Tag::VerticalMenu.
  #
  class MenuBaseTag < DefaultTag

    # Specialised node class for the menu. It encapsulates the original node in the node information
    # <tt>:node</tt> for later access. This has to be done to because otherwise the tree structure
    # of the main node tree would be corrupted.
    class MenuNode < Node

      def initialize( parent, node )
        super( parent, '' )
        self['title'] = 'Menu: ' + node['title']
        self.node_info[:node] = node
      end


      # Sorts recursively all children of the node depending on their order value. If two order
      # values are equal, sort the items using their title.
      def sort!
        self.children.sort! {|a,b| a.node_info[:node] <=> b.node_info[:node] }
        self.children.each {|child| child.sort! }
        self
      end

      def inspect
        @node_info[:node].absolute_lcn + " + " + children.inspect
      end
      alias_method :to_s, :inspect

      def to_lcn_list
        self.inject([]) {|temp, n| temp << n.node_info[:node].absolute_lcn; temp += ((t = n.to_lcn_list).empty? ? [] : [t]) }
      end

    end

    # Generates the menu tree for <tt>context.node</tt> and then delegates the actual menu
    # generation to #build_menu.
    def process_tag( tag, body, context )
      menu = @plugin_manager['Tag/MenuBaseTag'].menu_tree_for_lang( context.node['lang'], Node.root( context.node ) )

      (menu.nil? ? '' : build_menu( tag, body, context, menu ))
    end

    # Does the actual generation of the menu. Has to be implemented in derived menu tag plugins!
    def build_menu( tag, body, context, menu )
      raise NotImplementedError
    end

    #########
    protected
    #########

    # Returns style information (node is selected, ...) and a link from +src_node+ to +node+.
    def menu_item_details( src_node, node )
      styles = []
      styles << param( 'submenuClass' ) if node.is_directory?
      styles << param( 'submenuInHierarchyClass' ) if node.is_directory? && src_node.in_subtree_of?( node )
      styles << param( 'selectedMenuitemClass' ) if node == src_node
      style = "class=\"#{styles.join(' ')}\"" if styles.length > 0

      context = {
        :context => {
          :caller => self.class.plugin_name,
          :selected => (node == src_node),
          :directory => node.is_directory?,
          :inHierarchy => node.is_directory? && src_node.in_subtree_of?( node )
        }
      }
      link = node.node_for_lang( src_node['lang'] ).link_from( src_node, context )

      return style, link
    end

    # Returns the valid menu tree for the particular +node+.
    def menu_tree_for_lang( lang, root )
      @menus ||= {}
      unless @menus[lang]
        @menus[lang] = create_menu_tree( root, nil, lang )
        @menus[lang].sort! if @menus[lang]
      end
      @menus[lang]
    end

    # Creates and returns a menu tree if at least one node is in the menu or +nil+ otherwise.
    def create_menu_tree( node, parent, lang )
      menu_node = MenuNode.new( parent, node )
      parent.del_child( menu_node ) if parent

      node.select do |child|
        child['lang'] == lang || child['lang'].nil? || child.is_directory?
      end.each do |child|
        sub_node = create_menu_tree( child, menu_node, lang )
        menu_node.add_child( sub_node ) unless sub_node.nil?
      end

      return menu_node.has_children? ? menu_node : ( node['inMenu'] ? menu_node : nil )
    end

  end

end
