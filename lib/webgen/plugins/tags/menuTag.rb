#
#--
#
# $Id$
#
# webgen: a template based web page generator
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

require 'util/ups'
require 'webgen/node'
require 'webgen/plugins/tags/tags'

module Tags

  class MenuTag < UPS::Plugin

    class MenuNode < Node

      def initialize( parent, node )
        super parent
        self['title'] = 'Menu: '+ node['title']
        self['isMenuNode'] = true
        self['virtual'] = true
        self['node'] = node
      end

      def sort
        self.children.sort! do |a,b| get_order_value( a ) <=> get_order_value( b ) end
        self.children.each do |child| child.sort if child.kind_of?( MenuNode ) && child['node'].kind_of?( FileHandlers::DirHandler::DirNode ) end
      end

      def get_order_value( node )
        # be optimistic and try metainfo field first
        node = node['node'] if node.kind_of? MenuNode
        value = node['menuOrder']

        # find the first menuOrder entry in the page files
        node = node['indexFile'] if node.kind_of? FileHandlers::DirHandler::DirNode
        node = node.find do |child| child['menuOrder'] end if node.kind_of? FileHandlers::PagePlugin::PageNode
        value ||= node['menuOrder'] unless node.nil?

        # fallback value
        value ||= 0

        value
      end

    end


    NAME = 'Menu Tag'
    SHORT_DESC = 'Builds up a menu'

    Webgen::WebgenError.add_entry :TAG_PARAMETER_INVALID,
                                   "Missing or invalid parameter value for tag %0 in <%1>: %2",
                                   "Add or correct the parameter value"

    def init
      UPS::Registry['Tags'].tags['menu'] = self
    end


    def process_tag( tag, content, node, refNode )
      if !defined? @menuTree
        @menuTree = create_menu_tree( Node.root( node ), nil )
        #TODO only call DebugTreePrinter
        UPS::Registry['Tree Walker'].execute @menuTree unless @menuTree.nil?
        @menuTree.sort
        UPS::Registry['Tree Walker'].execute @menuTree unless @menuTree.nil?
      end
      if content.nil? || !content.has_key?( 'level' )
        raise Webgen::WebgenError.new( :TAG_PARAMETER_INVALID, tag, refNode.recursive_value( 'src' ), 'level' )
      end
      build_menu( node, @menuTree, content['level'] )
    end

    #######
    private
    #######

    def build_menu( srcNode, node, level )
      return '' unless level >= 1 && !node.nil?

      out = '<ul>'
      node.each do |child|
        if child.kind_of? MenuNode
          submenu = child['node'].kind_of?( FileHandlers::DirHandler::DirNode ) ? build_menu( srcNode, child, level - 1 ) : ''
          before, after = menu_entry( srcNode, child['node'] )
        else
          submenu = ''
          before, after = menu_entry( srcNode, child )
        end

        out << before
        out << submenu
        out << after
      end
      out << '</ul>'

      return out
    end


    def menu_entry( srcNode, node )
      langNode = node['processor'].get_lang_node( node, srcNode['lang'] )
      isDir = node.kind_of? FileHandlers::DirHandler::DirNode

      styles = []
      styles << 'submenu' if isDir
      styles << 'selectedMenu' if langNode.recursive_value( 'dest' ) == srcNode.recursive_value( 'dest' )

      style = " class=\"#{styles.join(' ')}\"" if styles.length > 0
      link = langNode['processor'].get_html_link( langNode, srcNode, ( isDir ? langNode['directoryName'] : langNode['title'] ) )

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
      menuNode = MenuNode.new( parent, node )

      node.each do |child|
        menu = create_menu_tree( child, menuNode )
        menuNode.add_child menu unless menu.nil?
      end

      return menuNode.has_children? ? menuNode : ( put_node_in_menu?( node ) ? node : nil )
    end


    def put_node_in_menu?( node )
      inMenu = node['inMenu']
      inMenu ||=  node.parent && node.parent.kind_of?( FileHandlers::PagePlugin::PageNode ) &&
                  node.parent.find do |child| child['inMenu'] end
      inMenu &&= !node['virtual']
      inMenu
    end

  end

  UPS::Registry.register_plugin MenuTag

end
