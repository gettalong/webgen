# -*- encoding: utf-8 -*-

require 'webgen/path_handler/base'
require 'webgen/context'

module Webgen
  class PathHandler

    # Simple path handler for copying files from the source to the destination, either without
    # changing anything or by applying content processors.
    class Copy

      include Base

      # Create the node for +path+.
      #
      # The following order is used for finding the (optional) content processor pipeline:
      #
      # * If the pipeline meta info key is specified, it is used.
      #
      # * If the +path+ has the names of content processors as parts in the file extension, all
      #   extension parts until the first non-content processor part will be used for the pipeline
      #   and removed from the extension.
      #
      #   If the last extension part is a file extension registered with a content processor (using
      #   the :ext_map facility), the corresponding content processor is appended to the pipeline
      #   and the post-process file extension name is used.
      #
      # Here are some examples:
      #
      # * pipeline = ['erb'] → only erb is used, extension is not modified
      #
      # * path = 'test.erb.kramdown.html', no pipeline → pipeline is set to ['erb', 'kramdown'] and
      #   path extension is changed to '.html', ie. path = 'test.html'
      #
      # * path = 'test.erb.kramdown.unknown.html', no pipeline → pipeline is set ['erb', 'kramdown']
      #   and path extension is changed to 'unknown.html', ie. path = 'test.unknown.html'
      #
      # * path = 'test.erb.sass', no pipeline → pipeline is set to ['erb', 'sass'] and path
      #   extension is changed to '.css', ie. path = 'test.css'
      #
      # * path = 'test.sass', no pipeline → pipeline is set to ['sass'] and path extension is
      #   changed to '.css', ie. path = 'test.css'
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
        path = @website.ext.source.paths[node.node_info[:path]]
        if pipeline = node.meta_info['pipeline']
          pipeline = @website.ext.content_processor.normalize_pipeline(pipeline)
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
