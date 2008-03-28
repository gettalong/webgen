module Webgen::SourceHandler

  module Base

    def create_node(parent, path)
      if !parent.children.any?{|c| c.path == path.basename || c.lcn == path.lcn}
        node = Webgen::Node.new(parent, path.basename, path.cn, path.lang, path.meta_info)
        node.node_info[:processor] = self
        yield(node) if block_given?
        node
      end
    end

  end

end
