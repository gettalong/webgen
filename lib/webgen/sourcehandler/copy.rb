module Webgen::SourceHandler

  # Simple source handler for copying files from the source tree, either verbatim or by applying a
  # content processor.
  class Copy

    include Webgen::WebsiteAccess
    include Base

    # Create the node for +parent+ and +path+. If the +path+ has the name of a content processor as
    # the first part in the extension, it is preprocessed.
    def create_node(parent, path)
      if path.ext.index('.')
        processor, *rest = path.ext.split('.')
        if website.blackboard.invoke(:content_processor_names).include?(processor)
          path.ext = rest.join('.')
        else
          processor = nil
        end
      end
      super(parent, path) do |node|
        node.node_info[:preprocessor] = processor
      end
    end

    # Return either the preprocessed content of the +node+ or the IO object for the node's source
    # path depending on the node type.
    def content(node)
      io = website.blackboard.invoke(:source_paths)[node.node_info[:src]].io
      if node.node_info[:preprocessor]
        context = Webgen::ContentProcessor::Context.new(:content => io.data, :chain => [node])
        website.blackboard.invoke(:content_processor, node.node_info[:preprocessor]).call(context)
        context.content
      else
        io
      end
    end

  end

end
