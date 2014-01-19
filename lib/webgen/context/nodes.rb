# -*- encoding: utf-8 -*-

module Webgen
  class Context

    # Provides quick access to special nodes of the node chain of a context object.
    module Nodes

      # Return the node which represents the file into which everything gets rendered.
      #
      # This is normally the same node as #content_node but can differ in special cases. For
      # example, when rendering the content of node called 'my.page' into the output of the node
      # 'this.page', 'this.page' would be the #dest_node and 'my.page' would be the #content_node.
      #
      # The #dest_node is not included in the chain but can be set via the option +:dest_node+!
      #
      # The returned node should be used as source node for calculating relative paths to other nodes.
      def dest_node
        @options[:dest_node] || content_node
      end

      # Return the reference node, ie. the node which provided the original content for this context
      # object.
      #
      # The returned node should be used, for example, for resolving relative paths.
      def ref_node
        @options[:chain][0]
      end

      # Return the node that is ultimately rendered.
      #
      # This node should be used, for example, for retrieving meta information.
      def content_node
        @options[:chain][-1]
      end
      alias :node :content_node

    end

  end
end
