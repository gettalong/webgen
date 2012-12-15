# -*- encoding: utf-8 -*-

require 'webgen/tag'

module Webgen
  class Tag

    # Generates a menu that can be extensively configured by using the available Webgen::NodeFinder
    # options.
    module Menu

      # Generate the menu.
      def self.call(tag, body, context)
        options = context[:config]['tag.menu.options']

        context[:nodes] = context.website.ext.node_finder.find(options, context.content_node)
        context.website.ext.item_tracker.add(context.dest_node, :nodes, :node_finder_option_set,
                                             {:opts => options, :ref_alcn => context.content_node.alcn}, :meta_info)

        if context[:nodes].empty?
          ''
        else
          Webgen::Tag.render_tag_template(context, "menu")
        end
      end

      # Return style information (node is selected, ...) and a link from +dest_node+ to +node+.
      #
      # This method can be used in a menu template.
      def self.menu_item_details(dest_node, node, lang, level, has_submenu)
        styles = ['webgen-menu-level' + level.to_s]
        styles << 'webgen-menu-submenu' if has_submenu
        styles << 'webgen-menu-submenu-inhierarchy' if node.is_ancestor_of?(dest_node)
        styles << 'webgen-menu-item-selected' if node == dest_node
        style = "class=\"#{styles.join(' ')}\"" if styles.length > 0

        link = dest_node.link_to(node, lang)

        [style, link]
      end

    end

  end
end
