require 'webgen/loggable'

module Webgen::ContentProcessor

  class Blocks

    include Webgen::Loggable

    BLOCK_RE = /<webgen:block\s+name=('|")(\w+)\1\s*(?:\schain=('|")([^'"]+)\3\s*)?\s*\/>/

    def call(context)
      chain = context[:chain]
      new_chain = (chain.length > 1 ? chain[1..-1] : chain)

      context.content.gsub!(BLOCK_RE) do |match|
        block_name = $2
        if $4.nil?
          used_chain = new_chain
        else
          paths = $4.split(';')
          used_chain = paths.collect do |path|
            temp_node = context.ref_node.resolve(path.strip, context.dest_node.lang)
            log(:error) { "Could not resolve <#{path.strip}> in <#{context.ref_node.absolute_lcn}> in '#{match.to_s}'" } if temp_node.nil?
            temp_node
          end.compact
          next match if used_chain.length != paths.length
          dest_node = context.content_node
        end
        block_node = used_chain.first

        if !block_node.node_info[:page].blocks.has_key?(block_name)
          raise "Node <#{block_node.absolute_lcn}> has no block named '#{block_name}'"
        end

        context.dest_node.node_info[:used_nodes] << block_node.absolute_lcn
        tmp_context = block_node.node_info[:page].blocks[block_name].render(context.clone(:chain => used_chain, :dest_node => dest_node))
        tmp_context.content
      end
      context
    end

  end

end
