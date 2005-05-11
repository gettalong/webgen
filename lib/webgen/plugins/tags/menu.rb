#
#--
#
# $Id$
#
# webgen: template based static website generator
# Copyright (C) 2004 Thomas Leitner
#
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU
# General Public License as published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program; if not,
# write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#++
#

require 'webgen/node'
require 'webgen/plugins/tags/tags'

module Tags

  # Generates a menu. All page files for which the meta information +inMenu+ is set are displayed.
  # If you have one page in several languages, it is sufficient to add this meta information to only
  # one page file.
  #
  # The order in which the menu items are listed can be controlled via the meta information
  # +orderInfo+. By default the menu items are sorted by the file names.
  #
  # Tag parameters:
  # [<b>level</b>]
  #   The depth of the menu. A level of one only displays the top level menu files. A level of two
  #   also displays the menu files in the direct subdirectories and so on.
  class MenuTag < DefaultTag


    class ::Node

      # Retrieves the meta information +orderInfo+.
      def order_info
        # be optimistic and try metainfo field first
        node = self
        value = node['orderInfo'].to_s.to_i unless node['orderInfo'].nil?

        # get index file for directory
        if node['int:directory?']
          node = node['indexFile']
          value ||= node['orderInfo'].to_s.to_i unless node.nil? || node['orderInfo'].nil?
        end

        # find the first orderInfo entry in the page files if node is a page file
        if !node.nil? && node['int:pagename']
          node = node.parent.find {|child| child['int:pagename'] == node['int:pagename'] && child['orderInfo'].to_s.to_i != 0}
          value ||= node['orderInfo'].to_s.to_i unless node.nil?
        end

        # fallback value
        value ||= 0

        value
      end

      SORT_PROC = Proc.new do |a,b|
        aoi = a.order_info
        boi = b.order_info
        (aoi == boi ? a['title'] <=> b['title'] : aoi <=> boi)
      end

    end

    # Specialised node class for the menu.
    class MenuNode < Node

      def initialize( parent, node )
        super( parent )
        self.logger.info { "Creating menu node for <#{node.recursive_value( 'src', false )}>" }
        self['title'] = 'Menu: '+ node['title']
        self['isMenuNode'] = true
        self['virtual'] = true
        self['node'] = node
      end


      # Sorts recursively all children of the node depending on their order value. If two order
      # values are equal, sort the items using their title.
      def sort!
        self.children.sort! {|a,b| SORT_PROC.call( a['node'], b['node'] ) }
        self.children.each {|child| child.sort! if child['node']['int:directory?'] }
      end

    end


    summary 'Builds a menu'
    depends_on 'Tags'

    add_param 'menuTag', 'ul', 'The tag used for submenus.'
    add_param 'itemTag', 'li', 'The tag used for menu items.'
    add_param 'submenuClass', 'webgen-submenu', 'Specifies the class of a submenu'
    add_param 'selectedMenuitemClass', 'webgen-menuitem-selected', 'Specifies the class of the selected menu item'
    add_param 'level', 1, \
    'Specifies how many levels the menu should have by default, ie. how deep it is. ' \
    'For example, if level = 3, then three levels are always shown at least.'
    add_param 'subtreeLevel', 3, \
    'Specifies how many levels should be shown for subtrees. The number specifies ' \
    'the maximum depth the menu will have.'
    add_param 'showCurrentSubtreeOnly', true, \
    'True if only the current subtree should be shown in the menu. If set to false, ' \
    'each subtree will be shown.'

    def initialize
      super
      register_tag( 'menu' )
    end

    def process_tag( tag, node, refNode )
      unless defined?( @menuTree )
        @menuTree = create_menu_tree( Node.root( node ), nil )
        unless @menuTree.nil?
          Webgen::Plugin['TreeWalker'].execute( @menuTree, Webgen::Plugin['DebugTreePrinter'] )
          @menuTree.sort!
          Webgen::Plugin['TreeWalker'].execute( @menuTree, Webgen::Plugin['DebugTreePrinter'] )
        end
      end
      build_menu( node, @menuTree, 1 )
    end


    #######
    private
    #######


    def build_menu( srcNode, node, level )
      if node.nil? \
        || level > get_param( 'subtreeLevel' ) \
        || ( level > get_param( 'level' ) \
             && ( node['node'].level > srcNode.level \
                  || ( get_param( 'showCurrentSubtreeOnly' ) && !srcNode.in_subtree?( node['node'] ) )
                  )
             )
        return ''
      end

      out = "<#{get_param( 'menuTag' )}>"
      node.each do |child|
        menu = child['node']['int:directory?'] ? build_menu( srcNode, child, level + 1 ) : ''
        before, after = menu_entry( srcNode, child['node'] )

        out << before
        out << menu
        out << after
      end
      out << "</#{get_param( 'menuTag' )}>"

      return out
    end


    def menu_entry( srcNode, node )
      langNode = node['processor'].get_node_for_lang( node, srcNode['lang'] )
      isDir = node['int:directory?']

      styles = []
      styles << get_param( 'submenuClass' ) if isDir
      styles << get_param( 'selectedMenuitemClass' ) if langNode.recursive_value( 'dest' ) == srcNode.recursive_value( 'dest' )

      style = " class=\"#{styles.join(' ')}\"" if styles.length > 0
      link = langNode['processor'].get_html_link( langNode, srcNode, ( isDir ? langNode['directoryName'] || node['directoryName'] : langNode['title'] ) )

      before = "<#{get_param( 'itemTag' )}#{style}>#{link}"
      after = "</#{get_param( 'itemTag' )}>"

      self.logger.debug { [before, after] }
      return before, after
    end


    def create_menu_tree( node, parent )
      menuNode = MenuNode.new( parent, node )

      node.each do |child|
        next if menuNode.find {|n| n['int:pagename'] == child['int:pagename'] && !n['int:pagename'].nil? }
        menu = create_menu_tree( child, menuNode )
        menuNode.add_child( menu ) unless menu.nil?
      end

      return menuNode.has_children? ? menuNode : ( node['inMenu'] && !node['virtual'] ? menuNode : nil )
    end

  end

end
