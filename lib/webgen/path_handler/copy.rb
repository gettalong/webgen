# -*- encoding: utf-8 -*-

require 'webgen/path_handler/base'
require 'webgen/context'

module Webgen
  class PathHandler

    # Simple path handler for copying files from the source to the destination, either without
    # changing anything or by applying one or more content processors.
    class Copy

      include Base

      # Create the node for +path+.
      #
      # See the user documentation for detailed information about how the content processor pipeline
      # can be specified.
      def create_nodes(path)
        if !path.meta_info.has_key?('pipeline')
          pipeline = []
          exts = path.ext.split('.')
          pipeline << exts.shift while exts.length > 1 && @website.ext.content_processor.registered?(exts.first)
          if (data = @website.ext.content_processor.map_extension(exts.last))
            pipeline << data.first
            exts[-1] = data.last
          end
          path.meta_info['pipeline'] = pipeline unless pipeline.empty?
          path.ext = exts.join('.')
        end

        create_node(path)
      end

      # Return the processed content of the +node+ if the pipeline meta info key is specified or the
      # IO object for the node's source path.
      def content(node)
        if pipeline = node.meta_info['pipeline']
          pipeline = @website.ext.content_processor.normalize_pipeline(pipeline)
          is_binary = @website.ext.content_processor.is_binary?(pipeline.first)
          context = Webgen::Context.new(@website, :chain => [node],
                                        :content => node.node_info[:path].data(is_binary ? 'rb' : 'r'))
          pipeline.each {|processor| @website.ext.content_processor.call(processor, context)}
          context.content
        else
          node.node_info[:path]
        end
      end

    end

  end
end
