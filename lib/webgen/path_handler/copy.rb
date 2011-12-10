# -*- encoding: utf-8 -*-

require 'webgen/path_handler/base'

module Webgen
  class PathHandler

    # Simple path handler for copying files from the source to the destination, either without
    # changing anything or by applying content processors.
    class Copy

      include Base

      # Create the node for +path+. If the +path+ has the name of a content processor as the first
      # part in the file extension or if the pipeline meta info key is specified, it is run through
      # the specified content processor(s).
      def create_nodes(path)
        if path.ext.index('.')
          processor, *rest = path.ext.split('.')
          if @website.ext.content_processor.registered?(processor)
            path.meta_info['pipeline'] ||= [processor]
            path.ext = rest.join('.')
          end
        end

        (path.meta_info['pipeline'] || []).each do |processor|
          if !@website.ext.content_processor.registered?(processor)
            raise Webgen::NodeCreationError.new("Unknown content processor '#{processor}'")
          end
        end
        create_node(path)
      end

      # Return the processed content of the +node+ if the pipeline meta info key is specified or the
      # IO object for the node's source path.
      def content(node)
        path = @website.ext.source.paths[node.node_info[:src]]
        if pipeline = node.meta_info['pipeline']
          is_binary = @website.ext.content_processor.is_binary?(pipeline.first)
          context = Webgen::Context.new(@website, :chain => [node], :content => path.data(is_binary ? 'rb' : 'r'))
          pipeline.each {|processor| @website.ext.content_processor.call(processor, context)}
          context.content
        else
          path
        end
      end

    end

  end
end
