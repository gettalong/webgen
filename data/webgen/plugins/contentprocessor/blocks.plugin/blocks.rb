module ContentProcessor

  class Blocks

    def process( content, context, options )
      chain = context[:chain]
      content.gsub( /<webgen:block\s+name=('|")(\w+)\1\s*\/>/ ) do |match|
        block_node = (chain.length > 1 ? chain[1] : chain[0])
        block_name = $2
        new_chain = (chain[1..-1].empty? ? chain : chain[1..-1])

        if block_node.node_info[:page].blocks.has_key?( block_name )
          result = block_node.node_info[:page].blocks[block_name].render( context.merge( :chain => new_chain ) )
        else
          raise "Node <#{block_node.node_info[:src]}> has no block named '#{block_name}'"
        end
      end
    end

  end

end
