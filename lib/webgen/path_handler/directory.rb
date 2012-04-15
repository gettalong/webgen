# -*- encoding: utf-8 -*-

require 'webgen/path_handler/base'

module Webgen
  class PathHandler

    # Path handler for directory source paths. Has nothing special to do.
    class Directory

      include Base

      # Create the node for +path+.
      def create_nodes(path)
        create_node(path)
      end

    end

  end
end
