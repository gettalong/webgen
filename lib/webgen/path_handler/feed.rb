# -*- encoding: utf-8 -*-

require 'webgen/path_handler/base'
require 'webgen/path_handler/page_utils'
require 'webgen/context'
require 'webgen/path'
require 'time'

module Webgen
  class PathHandler

    # Path handler for creating atom and/or rss feeds.
    #
    # When customizing a feed template one can use the following utiltity methods:
    #
    # * #feed_entries
    # * #feed_link
    # * #entry_content
    #
    # Have a look at the default feed templates to see them in action.
    class Feed

      include Base
      include PageUtils

      # The mandatory keys that need to be set in a feed file.
      MANDATORY_INFOS = %W[site_url author entries]

      # Create the feed nodes.
      def create_nodes(path, blocks)
        if MANDATORY_INFOS.any? {|t| path.meta_info[t].nil?}
          raise Webgen::NodeCreationError.new("At least one of #{MANDATORY_INFOS.join('/')} is missing",
                                              self.class.name, path)
        end

        create_feed_node = lambda do |type|
          path.ext = type
          create_node(path) do |node|
            set_blocks(node, blocks)
            node.meta_info['link'] ||= node.parent.alcn
            node.node_info[:feed_type] = type
            @website.ext.item_tracker.add(node, :nodes, :node_finder_option_set,
                                          {:opts => node['entries'], :ref_alcn => node.alcn}, :content)
          end
        end

        nodes = []
        nodes << create_feed_node['atom'] if path.meta_info['atom']
        nodes << create_feed_node['rss'] if path.meta_info['rss']
        nodes
      end

      # Return the rendered feed represented by +node+.
      def content(node)
        context = Webgen::Context.new(@website)
        context.render_block(:name => "#{node.node_info[:feed_type]}_template", :node => 'first',
                             :chain => [node, node.resolve("/templates/feed.template", node.lang, true), node].compact)
      end

      # Return the entries for the feed node.
      def feed_entries(node)
        @website.ext.node_finder.find(node['entries'], node)
      end

      # Return the feed link URL for the feed node.
      def feed_link(node)
        Webgen::Path.url(File.join(node['site_url'], node.tree[node['link']].dest_path), false)
      end

      # Return the content of an +entry+ of the feed +node+.
      def entry_content(node, entry)
        block_name = node['content_block_name'] || 'content'
        if entry.respond_to?(:render_block) && entry.blocks[block_name]
          entry.render_block(block_name, Webgen::Context.new(@website, :chain => [entry])).content
        else
          @website.logger.warn { "Feed entry <#{entry}> not used, is not a renderable node" }
          ''
        end
      end

    end

  end
end
