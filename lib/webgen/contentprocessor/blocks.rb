# -*- encoding: utf-8 -*-

module Webgen::ContentProcessor

  # Replaces special xml tags with the rendered content of a node.
  class Blocks

    include Webgen::Loggable

    BLOCK_RE = /<webgen:block\s*?((?:\s\w+=('|")[^'"]+\2)+)\s*\/>/
    BLOCK_ATTR_RE = /(\w+)=('|")([^'"]+)\2/

    # Replace the webgen:block xml tags with the rendered content of the specified node.
    def call(context)
      context.content.gsub!(BLOCK_RE) do |match|
        attr = {}
        match.scan(BLOCK_ATTR_RE) {|name, sep, content| attr[name.to_sym] = content}
        render_block(context, attr)
      end
      context
    end

    # Render a block of a page node and return the result.
    #
    # The Webgen::Context object +context+ is used as the render context and the +options+ hash
    # needs to hold all relevant information, that is:
    #
    # [<tt>:name</tt> (mandatory)]
    #   The name of the block that should be used.
    # [<tt>:chain</tt>]
    #   The node chain used for rendering. If this is not specified, the node chain from the context
    #   is used. It needs to be a String in the format <tt>(A)LCN;(A)LCN;...</tt> or an array of
    #   nodes.
    # [<tt>:node</tt>]
    #   Defines which node in the node chain should be used. Valid values are +next+ (= default
    #   value; the next node in the node chain), +first+ (the first node in the node chain with a
    #   block called +name+) or +current+ (the currently rendered node, ignores the +chain+ option).
    # [<tt>:notfound</tt>]
    #   If this property is set to +ignore+, a missing block will not raise an error. It is unset by
    #   default, so missing blocks will raise errors.
    def render_block(context, options)
      if options[:chain].nil?
        used_chain = (context[:chain].length > 1 ? context[:chain][1..-1] : context[:chain]).dup
      elsif options[:chain].kind_of?(Array)
        used_chain = options[:chain]
      else
        paths = options[:chain].split(';')
        used_chain = paths.collect do |path|
          temp_node = context.ref_node.resolve(path.strip, context.dest_node.lang)
          if temp_node.nil?
            context.dest_node.flag(:dirty)
            log(:error) { "Could not resolve <#{path.strip}> in <#{context.ref_node.alcn}> while rendering blocks" }
          end
          temp_node
        end.compact
        return '' if used_chain.length != paths.length
        dest_node = context.content_node
      end

      if options[:node] == 'first'
        used_chain.shift while used_chain.length > 0 && !used_chain.first.node_info[:page].blocks.has_key?(options[:name])
      elsif options[:node] == 'current'
        used_chain = context[:chain].dup
      end
      block_node = used_chain.first

      if !block_node || !block_node.node_info[:page].blocks.has_key?(options[:name])
        if options[:notfound] == 'ignore'
          return ''
        elsif block_node
          raise "Node <#{block_node.alcn}> has no block named '#{options[:name]}'"
        else
          raise "No node in the chain has a block named '#{options[:name]}'"
        end
      end

      context.dest_node.node_info[:used_nodes] << block_node.alcn
      tmp_context = block_node.node_info[:page].blocks[options[:name]].render(context.clone(:chain => used_chain, :dest_node => dest_node))
      tmp_context.content
    end

  end

end
