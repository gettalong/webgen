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

  class VerticalDropdownMenuStyle < MenuStyles::DefaultMenuStyle

    infos :summary => "Builds a vertical menu with CSS drop down submenus"

    register_handler 'vertical-dropdown'

    def initialize( plugin_manager )
      super
      @css = "
/* START webgen vertical dropdown menu style */
.webgen-menu-vert-dd ul {
  list-style-type: none;
  margin: 0;
  padding: 0;
  width: 15em;
}
.webgen-menu-vert-dd ul ul {
  border: 1px solid black;
  position: absolute;
  z-index: 500;
  left: 100%;
  top: 0;
}
.webgen-menu-vert-dd a {
  display: block;
  margin: 0px;
  padding: 3px 3px;
  background-color: white;
}
.webgen-menu-vert-dd li { position: relative; }
.webgen-menu-vert-dd ul ul { display: none; }
.webgen-menu-vert-dd ul li:hover > ul > ul { display: none; }
.webgen-menu-vert-dd ul li:hover > ul { display: block; }
/* STOP webgen vertical dropdown menu style */
"
    end

    def internal_build_menu( src_node, menu_tree )
      unless defined?( @css_added )
        @plugin_manager['CorePlugins::ResourceManager'].append_data( 'webgen-css', @css )
        @css_added = true
      end
      "<div class=\"webgen-menu-vert-dd #{param('divClass')}\">#{submenu( src_node, menu_tree, 1 )}</div>"
    end

    #######
    private
    #######

    def submenu( src_node, menu_node, level )
      out = ''
      out = "<ul>" if level > 1
      menu_node.each do |child|
        menu = (child.node_info['node'].is_directory? ? submenu( src_node, child, level + 1 ) : '')
        style, link = menu_item_details( src_node, child.node_info['node'] )

        out << "<ul>" if level == 1
        out << "<li #{style}>#{link}"
        out << menu
        out << "</li>"
        out << "</ul>" if level == 1
      end
      out << "</ul>" if level > 1

      return out
    end

  end

end
