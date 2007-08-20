require 'erb'

module ContentProcessor

  # Uses the builtin ERB to process the content.
  class Erb

    def process( content, context, options )
      chain = context[:chain]
      ref_node = chain.first
      node = chain.last
      used_nodes = {:nodes => [], :node_infos => []}

      erb = ERB.new( content )
      erb.filename = ref_node.node_info[:src] || ref_node.full_path
      [erb.result( binding ), used_nodes]
    end

  end

end
