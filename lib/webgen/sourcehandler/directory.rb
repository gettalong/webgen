require 'webgen/sourcehandler/base'

module Webgen::SourceHandler

  class Directory

    include Base

    def create_node(parent, path)
      if node = node_exists?(parent, path)
        node.meta_info.clear
        node.meta_info.update(path.meta_info)
        nil
      else
        super(parent, path)
      end
    end

    #TODO: Also need to handle virtual nodes (after they have been introduced) that shouldn't create
    #a real directory!!!
    def content(node)
      ''
    end

  end

end
