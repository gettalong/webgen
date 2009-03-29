# -*- encoding: utf-8 -*-

module Webgen::ContentProcessor

  # Replaces special xml tags with the rendered content of a node.
  class Blocks

    include Webgen::Loggable

    BLOCK_RE = /<webgen:block\s*?((?:\s\w+=('|")[^'"]+\2)+)\s*\/>/
    BLOCK_ATTR_RE = /(\w+)=('|")([^'"]+)\2/

    # Replace that webgen:block xml tags with the rendered content of a node.
    def call(context)
      chain = context[:chain]
      new_chain = (chain.length > 1 ? chain[1..-1] : chain)

      context.content.gsub!(BLOCK_RE) do |match|
        attr = {}
        match.scan(BLOCK_ATTR_RE) {|name, sep, content| attr[name] = content}
        if attr['chain'].nil?
          used_chain = new_chain.dup
        else
          paths = attr['chain'].split(';')
          used_chain = paths.collect do |path|
            temp_node = context.ref_node.resolve(path.strip, context.dest_node.lang)
            log(:error) { "Could not resolve <#{path.strip}> in <#{context.ref_node.absolute_lcn}> in '#{match.to_s}'" } if temp_node.nil?
            temp_node
          end.compact
          next match if used_chain.length != paths.length
          dest_node = context.content_node
        end

        if attr['node'] == 'first'
          used_chain.shift while used_chain.length > 0 && !used_chain.first.node_info[:page].blocks.has_key?(attr['name'])
        elsif attr['node'] == 'current'
          used_chain = context[:chain].dup
        end
        block_node = used_chain.first

        if !block_node || !block_node.node_info[:page].blocks.has_key?(attr['name'])
          if attr['notfound'] == 'ignore'
            next ''
          elsif block_node
            raise "Node <#{block_node.absolute_lcn}> has no block named '#{attr['name']}'"
          else
            raise "No node in the chain has a block named '#{attr['name']}'"
          end
        end

        context.dest_node.node_info[:used_nodes] << block_node.absolute_lcn
        tmp_context = block_node.node_info[:page].blocks[attr['name']].render(context.clone(:chain => used_chain, :dest_node => dest_node))
        tmp_context.content
      end
      context
    end

  end

end
