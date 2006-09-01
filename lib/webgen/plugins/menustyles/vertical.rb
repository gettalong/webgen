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

  class VerticalMenuStyle < MenuStyles::DefaultMenuStyle

    infos :summary => "Builds a vertical menu"

    register_handler 'vertical'

    param 'level', 1, 'Specifies how many levels the menu should have by default, ie. how deep it is. ' +
      'For example, if level = 3, then three levels are always shown at least.'
    param 'subtreeLevel', 3,  'Specifies how many levels should be shown for subtrees. The number ' +
      'specifies the maximum depth the menu will have.'
    param 'showCurrentSubtreeOnly', true, 'True if only the current subtree should be shown in the menu. ' +
      'If set to false, each subtree will be shown.'

    def initialize( plugin_manager )
      super
      @css = "
/* START webgen vertical menu style */
.webgen-menu-vert li > ul { font-size: 95%%; }
.webgen-menu-vert ul { padding: 0px; margin-left: 10px; }
.webgen-menu-vert li { padding-left: 5px; }
.webgen-menu-vert .%s > a { font-weight: bold; }
.webgen-menu-vert .%s > a { font-weight: bold; }
/* STOP webgen vertical menu style */
" % [ param( 'submenuInHierarchyClass' ), param( 'selectedMenuitemClass' )]
    end

    def internal_build_menu( src_node, menu_tree )
      unless defined?( @css_added )
        @plugin_manager['CorePlugins::ResourceManager'].append_data( 'webgen-css', @css )
        @css_added = true
      end
      "<div class=\"webgen-menu-vert #{param('divClass')}\">#{submenu( src_node, menu_tree, 1 )}</div>"
    end

    #######
    private
    #######

    def submenu( src_node, menu_node, level )
      if menu_node.nil? \
        || level > param( 'subtreeLevel' ) \
        || ( level > param( 'level' ) \
             && ( menu_node.node_info[:node].level > src_node.level \
                  || ( param( 'showCurrentSubtreeOnly' ) && !src_node.in_subtree_of?( menu_node.node_info[:node] ) )
                  )
             )
        return ''
      end

      out = "<ul>"
      menu_node.each do |child|
        menu = child.node_info[:node].is_directory? ? submenu( src_node, child, level + 1 ) : ''
        style, link = menu_item_details( src_node, child.node_info[:node] )

        out << "<li #{style}>#{link}"
        out << menu
        out << "</li>"
      end
      out << "</ul>"

      return out
    end

  end

end
