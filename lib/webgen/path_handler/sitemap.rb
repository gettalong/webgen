# -*- encoding: utf-8 -*-

require 'uri'
require 'time'
require 'webgen/path_handler/base'
require 'webgen/path_handler/page_utils'
require 'webgen/context'

module Webgen
  class PathHandler

    # Path handler for creating an XML sitemap based on the specification of http://sitemaps.org.
    class Sitemap

      include Base
      include PageUtils


      # Provides custom methods for sitemap nodes.
      class Node < PageUtils::Node

        # Return the entries for the sitemap +node+.
        def sitemap_entries
          tree.website.ext.node_finder.find(node_info[:entries], self)
        end

      end


      # The mandatory keys that need to be set in a sitemap file.
      MANDATORY_INFOS = %W[site_url entries]

      # Create an XML sitemap from +path+.
      def create_nodes(path, blocks)
        if MANDATORY_INFOS.any? {|t| path.meta_info[t].nil?}
          raise Webgen::NodeCreationError.new("At least one of #{MANDATORY_INFOS.join('/')} is missing",
                                              self.class.name, path)
        end

        path.ext = 'xml'
        create_node(path, Node) do |node|
          set_blocks(node, blocks)
          node.node_info[:entries] = {:flatten => true, :and => node['entries']}
          @website.ext.item_tracker.add(node, :nodes, :node_finder_option_set,
                                        {:opts => node.node_info[:entries], :ref_alcn => node.alcn}, :meta_info)
        end
      end

      # Return the rendered feed represented by +node+.
      def content(node)
        context = Webgen::Context.new(@website)
        context.render_block(:name => "sitemap", :node => 'first',
                             :chain => [node, node.resolve("/templates/sitemap.template", node.lang, true), node].compact)
      end

    end

  end
end
