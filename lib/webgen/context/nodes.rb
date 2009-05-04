module Webgen

  class Context

    # Return the node which represents the file into which everything gets rendered. This is normally
    # the same node as <tt>#content_node</tt> but can differ in special cases. For example, when
    # rendering the content of node called <tt>my.page</tt> into the output of the node
    # <tt>this.page</tt>, <tt>this.page</tt> would be the +dest_node+ and <tt>my.page</tt> would be
    # the +content_node+.
    #
    # The +dest_node+ is not included in the chain but can be set via the option <tt>:dest_node</tt>!
    #
    # The returned node should be used as source node for calculating relative paths to other nodes.
    def dest_node
      @options[:dest_node] || self.content_node
    end

    # Return the reference node, ie. the node which provided the original content for this context
    # object.
    #
    # The returned node should be used, for example, for resolving relative paths.
    def ref_node
      @options[:chain] && @options[:chain].first
    end

    # Return the node that is ultimately rendered.
    #
    # This node should be used, for example, for retrieving meta information.
    def content_node
      @options[:chain] && @options[:chain].last
    end
    alias :node :content_node

  end

end
