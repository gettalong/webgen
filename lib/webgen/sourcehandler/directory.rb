module Webgen::SourceHandler

  # Handles directory source paths.
  class Directory

    include Base
    include Webgen::WebsiteAccess

    def initialize # :nodoc:
      website.blackboard.add_service(:create_directories, method(:create_directories))
    end

    # Recursively create the directories specified in +dirname+ under +parent+ (a leading slash is
    # ignored). The path +path+ is the path that lead to the creation of these directories.
    def create_directories(parent, dirname, path)
      dirname.sub(/^\//, '').split('/').each do |dir|
        dir_path = Webgen::Path.new(File.join(parent.absolute_lcn, dir, '/'), path)
        nodes = website.blackboard.invoke(:create_nodes, parent.tree, parent.absolute_lcn,
                                           dir_path, self) do |dir_parent, dir_path|
          node_exists?(dir_parent, dir_path) || create_node(dir_parent, dir_path)
        end
        parent = nodes.first
      end
      parent
    end

    # Return an empty string to signal that the directory should be written to the output.
    def content(node)
      ''
    end

  end

end
