# -*- encoding: utf-8 -*-

require 'webgen/path_handler/base'
require 'webgen/path_handler/page_utils'

module Webgen
  class PathHandler

    # Path handler for handling content files in Webgen Page Format.
    class Page

      include Base
      include PageUtils

      # Create a page file from +path+.
      def create_nodes(path, blocks)
        path.meta_info['lang'] ||= @website.config['website.lang']
        path.ext = 'html' if path.ext == 'page'
        create_node(path) do |node|
          set_blocks(node, blocks)
        end
      end

      # Render the content of the given page +node+.
      def content(node)
        @website.ext.item_tracker.add(node, :template_chain, node)
        chain = node.template_chain << node
        chain.first.render_block('content', Webgen::Context.new(@website, :chain => chain)).content
      end

    end

  end
end
