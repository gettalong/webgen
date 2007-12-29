module ContentProcessor

  class Blocks

    BLOCK_RE = /<webgen:block\s+name=('|")(\w+)\1\s*(?:\schain=('|")([^'"]+)\3\s*)?\s*\/>/

    def process( context )
      chain = context.chain

      new_chain = (chain.length > 1 ? chain[1..-1] : chain)
      context.cache_info[plugin_name] ||= []

      context.content.gsub!( BLOCK_RE ) do |match|
        block_name = $2
        if $4.nil?
          used_chain = new_chain
        else
          paths = $4.split(';')
          used_chain = paths.collect do |path|
            temp_node = @plugin_manager['Core/CacheManager'].node_for_path( context.ref_node, path.strip, context.node['lang'] )
            log(:error) { "Could not resolve <#{path.strip}> in <#{context.ref_node.absolute_lcn}> in '#{match.to_s}'" } if temp_node.nil?
            temp_node
          end.compact
          next match if used_chain.length != paths.length
          dest_node = context.node
        end
        block_node = used_chain.first

        if !block_node.node_info[:page].blocks.has_key?( block_name )
          raise "Node <#{block_node.absolute_lcn}> has no block named '#{block_name}'"
        end

        log(:debug) { "Inserting rendered node <#{block_node.absolute_lcn}> into <#{chain.first.absolute_lcn}>" }
        context.cache_info[plugin_name] << block_node.absolute_lcn
        tmp_context = block_node.node_info[:page].blocks[block_name].render( context.clone(:chain => used_chain, :dest_node => dest_node) )
        tmp_context.content
      end
      context
    end

    def cache_info_changed?( nodes, node )
      @plugin_manager['Support/Misc'].nodes_changed?( nodes, node )
    end

  end

end
