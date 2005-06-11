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

  class VerticalMenuStyle < MenuStyles::DefaultMenuStyle

    summary "Builds a vertical menu"

    register_menu_style 'vertical'

    add_param 'level', 1, \
    'Specifies how many levels the menu should have by default, ie. how deep it is. ' \
    'For example, if level = 3, then three levels are always shown at least.'
    add_param 'subtreeLevel', 3, \
    'Specifies how many levels should be shown for subtrees. The number specifies ' \
    'the maximum depth the menu will have.'
    add_param 'showCurrentSubtreeOnly', true, \
    'True if only the current subtree should be shown in the menu. If set to false, ' \
    'each subtree will be shown.'

    CSS = "
/* START Webgen vertical menu style */
.webgen-menu-vert li > ul {
  font-size: 95%;
}

.webgen-menu-vert ul {
  padding: 0px;
  margin-left: 10px;
}

.webgen-menu-vert li {
  padding-left: 5px;
}

.webgen-menu-vert .webgen-menu-submenu-inhierarchy > a {
  font-weight: bold;
}

.webgen-menu-vert .webgen-menu-item-selected > a {
  font-weight: bold;
}
/* STOP Webgen vertical menu style */
"

    def internal_build_menu( srcNode, menuTree )
      unless defined?( @css_added )
        Webgen::Plugin['ResourceManager'].append_data( 'webgen-css', CSS )
        @css_added = true
      end
      "<div class=\"webgen-menu-vert #{get_param('divClass')}\">#{submenu( srcNode, menuTree, 1 )}</div>"
    end

    #######
    private
    #######

    def submenu( srcNode, node, level )
      if node.nil? \
        || level > get_param( 'subtreeLevel' ) \
        || ( level > get_param( 'level' ) \
             && ( node['node'].level > srcNode.level \
                  || ( get_param( 'showCurrentSubtreeOnly' ) && !srcNode.in_subtree?( node['node'] ) )
                  )
             )
        return ''
      end

      out = "<ul>"
      node.each do |child|
        menu = child['node']['int:directory?'] ? submenu( srcNode, child, level + 1 ) : ''
        style, link = menu_item_details( srcNode, child['node'] )

        out << "<li #{style}>#{link}"
        out << menu
        out << "</li>"
      end
      out << "</ul>"

      return out
    end

  end

end
