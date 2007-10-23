require 'erb'

module ContentProcessor

  # Uses the builtin ERB to process the content.
  class Erb

    def process( context )
      ref_node = context.ref_node
      node = context.node
      chain = context.chain

      erb = ERB.new( context.content )
      erb.filename = ref_node.node_info[:src] || ref_node.full_path
      context.content = erb.result( binding )
      context
    end

  end

end
