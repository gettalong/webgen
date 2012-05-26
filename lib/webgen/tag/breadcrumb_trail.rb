# -*- encoding: utf-8 -*-

require 'webgen/tag'

module Webgen
  class Tag

    # Generates a breadcrumb trail for the page. This is especially useful when pages are in deep
    # hierarchies of directories.
    module BreadcrumbTrail

      # Create the breadcrumb trail.
      def self.call(tag, body, context)
        options = {
          :alcn => context.content_node.alcn,
          :start_level => context[:config]['tag.breadcrumb_trail.start_level'],
          :end_level => context[:config]['tag.breadcrumb_trail.end_level'],
          :omit_dir_index => context[:config]['tag.breadcrumb_trail.omit_dir_index']
        }
        context.website.ext.item_tracker.add(context.dest_node, :nodes,
                                             ['Webgen::Tag::BreadcrumbTrail', 'nodes'], options, :meta_info)

        if (template_node = Webgen::Tag.resolve_tag_template(context, 'breadcrumb_trail'))
          context[:nodes] = nodes(context.website, options)
          context.render_block(:name => 'tag.breadcrumb_trail', :chain => [template_node, context.content_node])
        else
          ''
        end
      end

      # Return the list of nodes that make up the breadcrumb trail of a node while respecting the
      # parameters.
      #
      # The options hash needs to include the following keys:
      #
      # [:alcn]
      #    The alcn of the node for which the breadcrumb trail should be generated.
      #
      # [:start_level]
      #    The start level (an index into an array).
      #
      # [:end_level]
      #    The end level (an index into an array).
      #
      # [:omit_dir_index]
      #    If set, omits the last path component if it is a directory index.
      #
      def self.nodes(website, options)
        node = website.tree[options[:alcn]]
        nodes = []
        omit_dir_index = if node.meta_info.has_key?('omit_dir_index')
                           node['omit_dir_index']
                         else
                           options[:omit_dir_index]
                         end

        node = node.parent if omit_dir_index && node.parent.proxy_node(node.lang) == node

        until node == website.tree.dummy_root
          nodes.unshift(node)
          node = node.parent
        end
        nodes[options[:start_level]..options[:end_level]].to_a
      end

    end

  end
end
