require 'webgen/node'

module Webgen

  class Tree

    # The root node of the tree.
    attr_accessor :root

    # Direct access to a node via its absolute lcn.
    attr_reader :node_access

    # Processing information for a node.
    attr_reader :node_info

    def initialize
      @node_access = {}
      @node_info = {}
      @root = Node.new(self, '/')
    end

    # Delete the node identitied by +node_or_alcn+ from the tree.
    def delete_node(node_or_alcn)
      n = node_or_alcn.kind_of?(Node) ? node_or_alcn : node_access[alcn]
      return if n == @root

      n.parent.children.delete(n)
      node_access.delete(n.absolute_lcn)
      node_info.delete(n.absolute_lcn)
    end

    #TODO: doc
    def clean(source_paths)
      @node_access.each do |name, node|
        if !source_paths.include?(node.node_info[:src]) ||
            source_paths[node.node_info[:src]].changed? ||
            node.changed?
          delete_node(node)
        end
      end
    end

  end

end
