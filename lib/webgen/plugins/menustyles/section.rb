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

    param 'subtreeLevel', 3, 'Specifies how many levels should be shown. The number specifies ' +
      'the maximum depth the menu will have.'
    param 'dropdown', false, 'Specifies if the menu should be a drop-down menu'
    param 'numberSections', true, 'Specifies whether the section titles should be numbered'

=begin
TODO:
- test dropdown functionality
=end

    def initialize( plugin_manager )
      super
      @css = "
/* START webgen section menu style */
.webgen-menu-section-dropdown > ul { display: none; }
.webgen-menu-section-dropdown:hover > ul { display: block; }
/* STOP webgen section menu style */
"
    end

    def internal_build_menu( src_node, menu_tree )
      unless defined?( @css_added )
        @plugin_manager['Core/ResourceManager'].append_data( 'webgen-css', @css )
        @css_added = true
      end
      styles = ['webgen-menu-section',
                (param( 'dropdown' ) ? 'webgen-menu-section-dropdown' : ''),
                param( 'divClass' )]

      "<div class=\"#{styles.join(' ')}\">#{submenu( src_node.node_info[:pagesections], 1, '' )}</div>"
    end

    #######
    private
    #######

    def submenu( sections, level, number )
      return '' if sections.empty? || level > param( 'subtreeLevel' )

      out = ''
      out << "<ul>"
      sections.each_with_index do |child, index|
        index += 1
        child_number = number + index.to_s + '.'
        menu = (!child.subsections.empty? ? submenu( child.subsections, level + 1, child_number ) : '')

        out << "<li><a href=\"##{child.id}\">#{param('numberSections') ? child_number : ''} #{child.title}</a>"
        out << menu
        out << "</li>"
      end
      out << "</ul>"

      out
    end


=begin
      out = ''
      if get_param( 'dropdown' ) && level == src_node.level
        style, link = menu_item_details( src_node, menu_node['node'] )
        out << "#{link}"
      end

      out << "<ul>" if level >= src_node.level
      menu_node.each do |child|
        menu = child['node']['int:directory?'] ? submenu( src_node, child, level + 1 ) : ''
        style, link = menu_item_details( src_node, child['node'] )

        out << "<li #{style}>#{link}" if level >= src_node.level
        out << menu
        out << "</li>" if level >= src_node.level
      end
      out << "</ul>" if level >= src_node.level

      return out
    end
=end

  end

end
