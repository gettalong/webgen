# -*- encoding: utf-8 -*-

require 'webgen/path_handler'
require 'webgen/page'
require 'webgen/error'

module Webgen
  class PathHandler

    # This module should be used by path handlers that need to work with paths in Webgen Page Format.
    #
    # Note that this modules provides an implementation for the +parse_meta_info!+ method. If you
    # also include the Base module, make sure that you include before this module! Also make sure to
    # override this method if you need custom behaviour!
    module PageUtils

      # Calls #parse_as_page! to update the meta information hash of +path+. Returns the found
      # blocks which will be passed as second parameter to the #create_nodes method.
      def parse_meta_info!(path)
        parse_as_page!(path)
      end

      # Assume that the content of the given +path+ is in Webgen Page Format and parse it. Updates
      # 'path.meta_info' with the meta info from the page and returns the content blocks.
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
      # Uses the content processors specified for the block via the +blocks+ meta information key if
      # the +pipeline+ parameter is not set.
      #
      # Returns the given context with the rendered content.
      def render_block(node, name, context, pipeline = nil)
        unless node.blocks.has_key?(name)
          raise Webgen::RenderError.new("No block named '#{name}' found", self.class.name,
                                        context.dest_node.alcn, node.alcn)
        end

        content_processor = context.website.ext.content_processor
        context.website.ext.item_tracker.add(context.dest_node, :node_content, node.alcn)

        context.content = node.blocks[name].dup
        context[:block_name] = name
        pipeline ||= ((node.meta_info['blocks'] || {})[name] || {})['pipeline'] || []
        content_processor.normalize_pipeline(pipeline).each do |processor|
          content_processor.call(processor, context)
        end
        context[:block_name] = nil
        context
      end

    end

  end
end
