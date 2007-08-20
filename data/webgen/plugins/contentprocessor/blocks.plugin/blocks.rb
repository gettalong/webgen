module ContentProcessor

  class Blocks

    BLOCK_RE = /<webgen:block\s+name=('|")(\w+)\1\s*\/>/

    def process( content, context, options )
      chain = context[:chain]
      used_nodes = {}

      block_node = (chain.length > 1 ? chain[1] : chain[0])
      new_chain = (chain[1..-1].empty? ? chain : chain[1..-1])
      content = content.gsub( BLOCK_RE ) do |match|
        block_name = $2

        if block_node.node_info[:page].blocks.has_key?( block_name )
          log(:debug) { "Inserting rendered node <#{block_node.node_info[:src]}> into <#{chain.first.node_info[:src]}>" }
          (used_nodes[:nodes] ||= []) << block_node
          result, tmp_nodes = block_node.node_info[:page].blocks[block_name].render( context.merge( :chain => new_chain ) )
          tmp_nodes.each {|k,v| used_nodes[k] = (used_nodes[k] || []) + v}
        else
          raise "Node <#{block_node.node_info[:src]}> has no block named '#{block_name}'"
        end
        result
      end
      [content, used_nodes]
    end

  end

end
