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

  class DefaultMenuStyle < Webgen::HandlerPlugin

    infos :summary => "Base class for all menu styles"

    param 'divClass', '', 'Additional CSS class for the div-tag surrounding the menu'
    param 'submenuClass', 'webgen-menu-submenu', 'Specifies the class of a submenu.'
    param 'submenuInHierarchyClass', 'webgen-menu-submenu-inhierarchy', 'Specifies the class of the submenus which are ' \
    'in the hierarchy of the selected menu item.'
    param 'selectedMenuitemClass', 'webgen-menu-item-selected', 'Specifies the class of the selected menu item.'

    def build_menu( src_node, menu_tree, options )
      @options = options
      internal_build_menu( src_node, menu_tree )
    end

    def internal_build_menu( src_node, menu_tree )
      raise NotImplementedErorr
    end

    def param( name, plugin = nil )
      if defined?( @options) && !@options.nil? && @options.kind_of?( Hash ) && @options.has_key?( name ) &&
          self.class.config.params.has_key?( name )
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
      link = node.link_from( src_node )

      log(:debug) { [style, link] }
      return style, link
    end

  end

end
