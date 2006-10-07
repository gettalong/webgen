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

require 'webgen/node'
load_plugin 'webgen/plugins/tags/tag_processor'

module Tags

  # Generates a menu. All page files for which the meta information +inMenu+ is set are used.
  #
  # The order in which the menu items are listed can be controlled via the meta information
  # +orderInfo+. By default the menu items are sorted by their titles.
  class MenuTag < DefaultTag

    # Specialised node class for the menu.
    class MenuNode < Node

      def initialize( parent, node )
        super( parent, '' )
        self['title'] = 'Menu: ' + node['title']
        self.node_info[:node] = node
      end


      # Sorts recursively all children of the node depending on their order value. If two order
      # values are equal, sort the items using their title.
      def sort!
        self.children.sort! {|a,b| a.node_info[:node] <=> b.node_info[:node] }
        self.children.each {|child| child.sort! }
      end

      def inspect
        @node_info[:node]
      end
      alias_method :to_s, :inspect

    end


    infos :summary => 'Builds a menu'
    param 'menuStyle', nil, 'Specifies the style of the menu.'
    param 'options', {}, 'Options that are passed on to the plugin which layouts the menu.'
    set_mandatory 'menuStyle', true

=begin
TODO: move to doc
- used_meta_info 'orderInfo', 'inMenu'
=end

    register_tag 'menu'

    def process_tag( tag, chain )
      lang = chain.last['lang']
      @menus ||= {}
      unless @menus[lang]
        @menus[lang] = create_menu_tree( Node.root( chain.last ), nil, lang )
        @menus[lang].sort! if @menus[lang]
      end

      style = @plugin_manager['MenuStyle/Default'].registered_handlers[param( 'menuStyle' )]
      if style.nil?
        log(:error) { "Invalid style specified in <#{chain.first.node_info[:src]}>" }
        ''
      elsif @menus[lang]
        style.build_menu( chain.last, @menus[lang], param( 'options' ) )
      else
        ''
      end
    end


    #######
    private
    #######

    # Returns a menu tree if at least one node is in the menu or +nil+ otherwise.
    def create_menu_tree( node, parent, lang )
      menu_node = MenuNode.new( parent, node )
      parent.del_child( menu_node ) if parent

      node.select do |child|
        child['lang'] == lang || child['lang'].nil? || child.is_directory?
      end.each do |child|
        sub_node = create_menu_tree( child, menu_node, lang )
        menu_node.add_child( sub_node ) unless sub_node.nil?
      end if node.is_directory?

      return menu_node.has_children? ? menu_node : ( node['inMenu'] ? menu_node : nil )
    end

=begin
TODO: move to doc
- no static menu, but can be built using output backing file
  - you can use exisiting page files by specifying the file directly:
    features.page:
      inMenu: true
      orderInfo: 1
  - you can add non-existing files and directories to structure the menu the way you like it,
    also add on page under two headings
    newdir:
      orderInfo: 2
    newdir/new.page:
      orderInfo: 1       -> orderInfo for subdir
      inMenu: true
      lang: en           -> lang has to be set explicitly if named file does not exist, and if
                            the file should only appear in the english menu, if not set, appears
                            in every menu
      url: ../features.page  -> ../features.page is shown

- menu structure:
  - Menu Title: /doit.page
  - Other Title: /doit.page
  - Again: /subdir/doit.page
  - Category:
    - item: /doit.page
    - item: /subdir/doit.page
=end

  end

end
