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

  class SectionMenuStyle < MenuStyles::DefaultMenuStyle

    plugin_name 'MenuStyle/Section'
    infos :summary => "Builds a menu out of the HTML sections (h1, h2, ...)"

    register_handler 'section'

    param 'maxLevels', 3, 'Specifies the maximum number of levels that should be shown.'
    param 'numberSections', true, 'Specifies whether the section titles should be numbered'

    def internal_build_menu( src_node, menu_tree )
      "<div class=\"webgen-menu-section #{param('divClass')}\">#{submenu( src_node.node_info[:pagesections], 1, '' )}</div>"
    end

    #######
    private
    #######

    def submenu( sections, level, number )
      return '' if sections.empty? || level > param( 'maxLevels' )

      out = ''
      out << "<ul>"
      sections.each_with_index do |child, index|
        index += 1
        child_number = number + index.to_s + '.'
        menu = (!child.subsections.empty? ? submenu( child.subsections, level + 1, child_number ) : '')

        out << "<li><a href=\"##{child.id}\">#{param('numberSections') ? child_number + ' ': ''}#{child.title}</a>"
        out << menu
        out << "</li>"
      end
      out << "</ul>"

      out
    end

  end

end
