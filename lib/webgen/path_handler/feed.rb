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


      # Provides custom methods needed for feed nodes.
      class Node < PageUtils::Node

        # Return the entries for this feed node.
        def feed_entries
          tree.website.ext.node_finder.find(self['entries'], self)
        end

        # Return the feed link URL for this feed node.
        def feed_link
          tree[self['link']].url
        end

        # Return the content of an +entry+ (a Node object) of this feed node.
        def entry_content(entry)
          block_name = self['content_block_name'] || 'content'
          if entry.respond_to?(:render_block) && entry.blocks[block_name]
            entry.render_block(block_name, Webgen::Context.new(tree.website, :chain => [entry])).content
          else
            tree.website.logger.warn { "Feed entry <#{entry}> not used, is not a renderable node" }
            ''
          end
        end

      end


      # The mandatory keys that need to be set in a feed file.
      MANDATORY_INFOS = %W[author entries]

      # Create the feed nodes.
      def create_nodes(path, blocks)
        if MANDATORY_INFOS.any? {|t| path.meta_info[t].nil?}
          raise Webgen::NodeCreationError.new("At least one of #{MANDATORY_INFOS.join('/')} is missing",
                                              "path_handler.feed", path)
        end
        if @website.config['website.base_url'].empty?
          raise Webgen::NodeCreationError.new("The configuration option 'website.base_url' needs to be set",
                                              "path_handler.feed", path)
        end
        if !['atom', 'rss'].include?(path['version'])
          raise Webgen::NodeCreationError.new("Invalid version '#{path['version']}' for feed path specified, only atom and rss allowed",
                                              "path_handler.feed", path)
        end

        path.ext = path['version']
        path['dest_path'] = '<parent><basename>(.<lang>)<ext>'
        path['cn'] = '<basename><ext>'
        path['node_class'] = Node.to_s
        create_node(path) do |node|
          set_blocks(node, blocks)
          node.meta_info['link'] ||= node.parent.alcn
          @website.ext.item_tracker.add(node, :nodes, :node_finder_option_set,
                                        {:opts => node['entries'], :ref_alcn => node.alcn}, :content)
        end
      end

      # Return the rendered feed represented by +node+.
      def content(node)
        context = Webgen::Context.new(@website)
        context.render_block(:name => "#{node['version']}_template", :node => 'first',
                             :chain => [node, node.resolve("/templates/feed.template", node.lang, true), node].compact)
      end

    end

  end
end
