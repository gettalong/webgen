module Webgen::SourceHandler

  # Handles directory source paths.
  class Directory

    include Base

    # Creation of directory nodes is special because once they are created, they are only deleted
    # when the source path gets deleted. Otherwise, only the meta information of the node gets
    # updated.
    def create_node(parent, path)
      if node = node_exists?(parent, path)
        node.meta_info.clear
        node.meta_info.update(path.meta_info)
        node.dirty = true
        node
      else
        super(parent, path)
      end
    end

    # Return an empty string to signal that the directory should be written to the output.
    def content(node)
      ''
    end

  end

end
