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
    add_param 'menuStyle', 'vertical', 'Specifies the style of the menu.'
    add_param 'options', {}, 'Optional options that are passed on to the plugin which is layouts the menu.'

    used_meta_info 'orderInfo', 'inMenu'

    tag 'menu'

    def process_tag( tag, node, refNode )
      unless defined?( @menuTree )
        @menuTree = create_menu_tree( Node.root( node ), nil )
        unless @menuTree.nil?
          Webgen::Plugin['TreeWalker'].execute( @menuTree, Webgen::Plugin['DebugTreePrinter'] )
          @menuTree.sort!
          Webgen::Plugin['TreeWalker'].execute( @menuTree, Webgen::Plugin['DebugTreePrinter'] )
        end
      end
      Webgen::Plugin['DefaultMenuStyle'].get_menu_style( get_param( 'menuStyle' ) ).build_menu( node, @menuTree, get_param( 'options' ) )
    end


    #######
    private
    #######

    def create_menu_tree( node, parent )
      menuNode = MenuNode.new( parent, node )

      node.each do |child|
        next if menuNode.find {|n| n['node']['int:pagename'] == child['int:pagename'] && !n['node']['int:pagename'].nil? }
        menu = create_menu_tree( child, menuNode )
        menuNode.add_child( menu ) unless menu.nil?
      end

      return menuNode.has_children? ? menuNode : ( node['inMenu'] && !node['virtual'] ? menuNode : nil )
    end

  end

end
