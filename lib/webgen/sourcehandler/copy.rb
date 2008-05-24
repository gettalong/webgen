module Webgen::SourceHandler

  class Copy

    include Webgen::WebsiteAccess
    include Base

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

    def content(node)
      io = website.blackboard.invoke(:source_paths)[node.node_info[:src]].io
      if node.node_info[:preprocessor]
        context = Webgen::ContentProcessor::Context.new(io.read, :chain => [node])
        website.blackboard.invoke(:content_processor, node.node_info[:preprocessor]).call(context)
        context.content
      else
        io
      end
    end

  end

end
