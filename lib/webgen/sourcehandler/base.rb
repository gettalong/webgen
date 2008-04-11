module Webgen::SourceHandler

  module Base

    def node_exists?(parent, path)
      parent.children.find {|c| c.path == path.basename || c.lcn == path.lcn}
    end

    def create_node(parent, path)
      if !node_exists?(parent, path)
        node = Webgen::Node.new(parent, path.basename, path.cn, path.lang, path.meta_info.dup)
        node.node_info[:processor] = self
        yield(node) if block_given?
        node
      end
    end

    def content(node)
      nil
    end

  end

end
