require 'erb'

module ContentProcessor

  # Uses the builtin ERB to process the content.
  class Erb

    def process( context )
      ref_node = context.ref_node
      node = context.node
      chain = context.chain
      used_nodes = []

      erb = ERB.new( context.content )
      erb.filename = ref_node.node_info[:src] || ref_node.full_path
      context.content = erb.result( binding )
      context.cache_info[plugin_name] ||= []
      context.cache_info[plugin_name] += used_nodes.collect {|n| n.absolute_lcn}
      context
    end

    def cache_info_changed?( nodes, node )
      @plugin_manager['Support/Misc'].nodes_changed?( nodes, node )
    end

  end

end
