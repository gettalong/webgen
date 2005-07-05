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


module MenuStyles

  class DefaultMenuStyle < Webgen::Plugin

    summary "Base class for all menu styles"

    define_handler 'menu_style'

    add_param 'divClass', '', 'Additional CSS class for the div-tag surrounding the menu'
    add_param 'submenuClass', 'webgen-menu-submenu', 'Specifies the class of a submenu.'
    add_param 'submenuInHierarchyClass', 'webgen-menu-submenu-inhierarchy', 'Specifies the class of the submenus which are ' \
    'in the hierarchy of the selected menu item.'
    add_param 'selectedMenuitemClass', 'webgen-menu-item-selected', 'Specifies the class of the selected menu item.'

    def build_menu( srcNode, menuTree, options )
      @options = options
      internal_build_menu( srcNode, menuTree )
    end

    def internal_build_menu( srcNode, menuTree )
      ""
    end

    def get_param( name )
      ( !@options.nil? && @options.kind_of?( Hash ) && @options.has_key?( name ) ? @options[name] : super )
    end

    #########
    protected
    #########

    # Returns style information (node is selected, ...) and link for +node+ relative to +srcNode+.
    def menu_item_details( srcNode, node )
      langNode = node['processor'].get_node_for_lang( node, srcNode['lang'] )
      isDir = node['int:directory?']

      styles = []
      styles << get_param( 'submenuClass' ) if isDir
      styles << get_param( 'submenuInHierarchyClass' ) if isDir && srcNode.in_subtree?( node )
      styles << get_param( 'selectedMenuitemClass' ) if langNode.recursive_value( 'dest' ) == srcNode.recursive_value( 'dest' )

      style = "class=\"#{styles.join(' ')}\"" if styles.length > 0
      link = node['processor'].get_html_link( node, srcNode )

      self.logger.debug { [style, link] }
      return style, link
    end

  end

end
