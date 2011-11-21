# -*- encoding: utf-8 -*-

require 'webgen/path_handler'
require 'webgen/page'
require 'webgen/error'

module Webgen
  class PathHandler

    module PageUtils

      # Assume that the content of the given +path+ is in Webgen Page Format and parse it. Updates
      # <tt>path.meta_info</tt> with the meta info from the page and stores the content blocks in
      # the @blocks variable.
      def parse_as_page!(path)
        begin
          page = Webgen::Page.from_data(path.data, path.meta_info)
        rescue Webgen::Page::FormatError => e
          raise Webgen::Error.new("Error reading source path: #{e.message}", self.class.name, path)
        end
        path.meta_info.replace(page.meta_info)
        page.blocks
      end
      private :parse_as_page!

      # Set the blocks (see #parse_as_page!) for the node.
      def set_blocks(node, blocks)
        node.node_info[:blocks] = blocks
      end
      private :set_blocks

      # Return the blocks (see #parse_as_page!) for the node.
      def blocks(node)
        node.node_info[:blocks]
      end

      # Render the block +name+ of +node+ using the provided Context object.
      #
      # Uses the content processors specified in the +pipeline+ key of the block if the +pipeline+
      # parameter is not set.
      #
      # Returns the given context with the rendered content.
      def render_block(node, name, context, pipeline = nil)
        unless node.blocks.has_key?(name)
          raise Webgen::RenderError.new("No block named '#{name}' found", self.class.name,
                                        context.dest_node.alcn, node.alcn)
        end
        context.content = node.blocks[name].content.dup
        pipeline ||= ((node.meta_info['blocks'] || {})[name] || {})['pipeline'] || []
        content_processor = context.website.ext.content_processor
        pipeline.each do |processor|
          unless content_processor.registered?(processor)
            raise Webgen::RenderError.new("No such content processor available: #{processor}", self.class.name, node.alcn)
          end
          content_processor.call(processor, context)
        end
        context
      end

    end

  end
end
