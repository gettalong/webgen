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

require 'webgen/plugins/menustyles/default'

module MenuStyles

  class HorizontalMenuStyle < MenuStyles::DefaultMenuStyle

    summary "Builds a horizontal menu"

    register_menu_style 'horizontal'

    CSS = "
/* START Webgen horizontal menu style */
.webgen-menu-horiz {
  text-align: center;
}

.webgen-menu-horiz ul {
  display: block;
  margin: 0px;
  padding-bottom: 3px;
  margin-bottom: 3px;
}

.webgen-menu-horiz li {
  display: inline;
  padding: 0px 5px;
}

.webgen-menu-horiz .webgen-menu-submenu-inhierarchy {
  font-weight: bold;
}

.webgen-menu-horiz .webgen-menu-item-selected {
  font-weight: bold;
}
/* STOP Webgen horizontal menu style */
"

    def internal_build_menu( srcNode, menuTree )
      unless defined?( @css_added )
        Webgen::Plugin['ResourceManager'].append_data( 'webgen-css', CSS )
        @css_added = true
      end
      "<div class=\"webgen-menu-horiz #{get_param('divClass')}\">#{submenu( srcNode, menuTree, 1 )}</div>"
    end

    #######
    private
    #######

    def submenu( srcNode, node, level )
      if node.nil? || node['node'].level > srcNode.level || !srcNode.in_subtree?( node['node'] )
        return ''
      end

      submenu = ''
      out = "<ul>"
      node.each do |child|
        submenu << (child['node']['int:directory?'] ? submenu( srcNode, child, level + 1 ) : '')
        style, link = menu_item_details( srcNode, child['node'] )
        out << "<li #{style}>#{link}</li>"
      end
      out << "</ul>"
      out << submenu

      return out
    end

  end

end
