# -*- encoding: utf-8 -*-

require 'webgen/path_handler/base'
require 'webgen/path_handler/page_utils'

module Webgen
  class PathHandler

    # Path handler for handling template files in Webgen Page Format.
    class Template

      include Base
      include PageUtils

      # Create a template node for +path+.
      def create_nodes(path, blocks)
        create_node(path) do |node|
          node.meta_info['no_output'] = true
          set_blocks(node, blocks)
        end
      end

    end

  end
end
