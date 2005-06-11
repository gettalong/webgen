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

require 'webgen/plugins/menustyles/defaultmenustyle'

module MenuStyles

  class PartialMenuStyle < MenuStyles::DefaultMenuStyle

    summary "Builds a partial menu"
    description "Creates a menu that only shows the menu levels under the current page"

    register_menu_style 'partial'

    add_param 'subtreeLevel', 1, \
    'Specifies how many levels should be shown. The number specifies ' \
    'the maximum depth the menu will have.'
    add_param 'dropdown', false, 'Specifies if the menu should be a drop-down menu'

    CSS = "
/* START Webgen partial menu style */
.webgen-menu-partial-dropdown > ul {
  display: none;
}

.webgen-menu-partial-dropdown:hover > ul {
  display: block;
}
/* STOP Webgen partial menu style */
"

    def internal_build_menu( srcNode, menuTree )
      unless defined?( @css_added )
        Webgen::Plugin['ResourceManager'].append_data( 'webgen-css', CSS )
        @css_added = true
      end
      styles = ['webgen-menu-partial',
                (get_param( 'dropdown' ) ? 'webgen-menu-partial-dropdown' : ''),
                get_param( 'divClass' )]

      "<div class=\"#{styles.join(' ')}\">#{submenu( srcNode, menuTree, 1 )}</div>"
    end

    #######
    private
    #######

    def submenu( srcNode, node, level )
      if node.nil? || level - srcNode.level >= get_param( 'subtreeLevel' ) || \
        (level >= srcNode.level && !node['node'].in_subtree?( srcNode ))
        return ''
      end

      out = ''
      if get_param( 'dropdown' ) && level == srcNode.level
        style, link = menu_item_details( srcNode, node['node'] )
        out << "#{link}"
      end

      out << "<ul>" if level >= srcNode.level
      node.each do |child|
        menu = child['node']['int:directory?'] ? submenu( srcNode, child, level + 1 ) : ''
        style, link = menu_item_details( srcNode, child['node'] )

        out << "<li #{style}>#{link}" if level >= srcNode.level
        out << menu
        out << "</li>" if level >= srcNode.level
      end
      out << "</ul>" if level >= srcNode.level

      return out
    end

  end

end
