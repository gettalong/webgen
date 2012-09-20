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

      # Render the block +block_name+ of the given +node+.
      #
      # If the parameter +chain+ (an array of template nodes) is not set, the default template chain
      # for the given +node+ is used.
      def content(node, block_name = 'content', chain = nil)
        chain ||= @website.ext.path_handler.instance(:template).template_chain(node)
        chain << node

        chain.first.render_block(block_name, Webgen::Context.new(@website, :chain => chain)).content
      end

    end

  end
end
