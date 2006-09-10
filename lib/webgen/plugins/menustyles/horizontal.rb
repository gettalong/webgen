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

load_plugin 'webgen/plugins/menustyles/default'

module MenuStyles

  class HorizontalMenuStyle < DefaultMenuStyle

    plugin_name 'MenuStyle/Horizontal'
    infos :summary => "Builds a horizontal menu"

    register_handler 'horizontal'

    def internal_build_menu( src_node, menu_tree )
      unless defined?( @css_added )
        @plugin_manager['Core/ResourceManager'].append_data( 'webgen-css', "
/* START webgen horizontal menu style */
.webgen-menu-horiz ul { display: block; }
.webgen-menu-horiz li { display: inline; }
/* STOP webgen horizontal menu style */
" )
        @css_added = true
      end
      "<div class=\"webgen-menu-horiz #{param('divClass')}\">#{submenu( src_node, menu_tree, 1 )}</div>"
    end

    #######
    private
    #######

    def submenu( src_node, menu_node, level )
      if menu_node.nil? || menu_node.node_info[:node].level > src_node.level \
        || !src_node.in_subtree_of?( menu_node.node_info[:node] )
        return ''
      end

      submenu = ''
      out = "<ul>"
      menu_node.each do |child|
        submenu << (child.node_info[:node].is_directory? ? submenu( src_node, child, level + 1 ) : '')
        style, link = menu_item_details( src_node, child.node_info[:node] )
        out << "<li #{style}>#{link}</li>"
      end
      out << "</ul>"
      out << submenu

      return out
    end

  end

end
