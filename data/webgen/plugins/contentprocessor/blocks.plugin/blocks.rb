module ContentProcessor

  class Blocks

    BLOCK_RE = /<webgen:block\s+name=('|")(\w+)\1\s*\/>/

    def process( context )
      chain = context.chain

      block_node = (chain.length > 1 ? chain[1] : chain[0])
      new_chain = (chain[1..-1].empty? ? chain : chain[1..-1])
      context.cache_info[plugin_name] ||= []

      context.content.gsub!( BLOCK_RE ) do |match|
        block_name = $2

        if !block_node.node_info[:page].blocks.has_key?( block_name )
          raise "Node <#{block_node.node_info[:src]}> has no block named '#{block_name}'"
        end

        log(:debug) { "Inserting rendered node <#{block_node.node_info[:src]}> into <#{chain.first.node_info[:src]}>" }
        context.cache_info[plugin_name] << block_node.absolute_lcn
        tmp_context = block_node.node_info[:page].blocks[block_name].render( context.clone(:chain => new_chain) )
        tmp_context.content
      end
      context
    end

    def cache_info_changed?( nodes, node )
      fh = @plugin_manager['Core/FileHandler']
      cm = @plugin_manager['Core/CacheManager']
      nodes.any? {|p| n = cm.node_for_path( node, p ); n.nil? || (n != node && fh.node_changed?( n )) }
    end

  end

end
