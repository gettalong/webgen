require 'webgen/node'

module Tag

  # Generates a menu. All page files for which the meta information +inMenu+ is set are used.
  #
  # The order in which the menu items are listed can be controlled via the meta information
  # +orderInfo+.
  class MenuBaseTag < DefaultTag

    # Specialised node class for the menu.
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
      end

      def inspect
        @node_info[:node]
      end
      alias_method :to_s, :inspect

    end


    def process_tag( tag, body, ref_node, node )
      menu = @plugin_manager['Tag/MenuBaseTag'].menu_tree_for_node( node )

      if menu
        build_menu( node, menu )
      else
        ''
      end
    end

    def build_menu( src_node, menu_tree )
      raise NotImplementedError
    end

    def param( name, plugin = nil )
      if defined?( @options ) && !@options.nil? && @options.kind_of?( Hash ) && @options.has_key?( name ) #&&
        #self.class.ancestor_classes.any? {|klass| klass.config.params.has_key?( name )} #TODO use other check
        @options[name]
      else
        super
      end
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
      link = node.link_from( src_node, :context => {
                               :caller => self.class.plugin_name,
                               :selected => (node == src_node),
                               :directory => node.is_directory?,
                               :inHierarchy => node.is_directory? && src_node.in_subtree_of?( node )
                             } )

      return style, link
    end

    def menu_tree_for_node( node )
      lang = node['lang']
      @menus ||= {}
      unless @menus[lang]
        @menus[lang] = create_menu_tree( Node.root( node ), nil, lang )
        @menus[lang].sort! if @menus[lang]
      end
      @menus[lang]
    end

    # Returns a menu tree if at least one node is in the menu or +nil+ otherwise.
    def create_menu_tree( node, parent, lang )
      menu_node = MenuNode.new( parent, node )
      parent.del_child( menu_node ) if parent

      node.select do |child|
        child['lang'] == lang || child['lang'].nil? || child.is_directory?
      end.each do |child|
        sub_node = create_menu_tree( child, menu_node, lang )
        menu_node.add_child( sub_node ) unless sub_node.nil?
      end if node.is_directory?

      return menu_node.has_children? ? menu_node : ( node['inMenu'] ? menu_node : nil )
    end

  end

end
