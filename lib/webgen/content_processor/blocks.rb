# -*- encoding: utf-8 -*-

require 'webgen/content_processor'
require 'webgen/error'

module Webgen
  class ContentProcessor

    # Replaces special XML tags with the rendered content of a node block.
    #
    # The module provides a .call method so that it can be used by the content processor extension.
    # However, it also provides the .render_block method that contains the actual logic for
    # rendering a block of a node given a render context.
    module Blocks

      BLOCK_RE = /<webgen:block\s*?((?:\s\w+=('|")[^'"]+\2)+)\s*\/>/
      BLOCK_ATTR_RE = /(\w+)=('|")([^'"]+)\2/

      # Replace the webgen:block xml tags with the rendered content of the specified node.
      def self.call(context)
        context.content.gsub!(BLOCK_RE) do |match|
          attr = {}
          match_object = $~
          attr[:line_nr_proc] = lambda { match_object.pre_match.scan("\n").size + 1 }
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
      #
      def self.render_block(context, options)
        if options[:chain].nil?
          used_chain = (context[:chain].length > 1 ? context[:chain][1..-1] : context[:chain].dup)
        elsif options[:chain].kind_of?(Array)
          used_chain = options[:chain]
          dest_node = context.content_node
        else
          paths = options[:chain].split(';')
          used_chain = paths.collect do |path|
            temp_node = context.ref_node.resolve(path.strip, context.dest_node.lang)
            if temp_node.nil?
              raise Webgen::RenderError.new("Could not resolve <#{path.strip}>",
                                            self.class.name, context.dest_node,
                                            context.ref_node, (options[:line_nr_proc].call if options[:line_nr_proc]))
            end
            temp_node
          end.compact
          return '' if used_chain.length != paths.length
          dest_node = context.content_node
        end

        if options[:node] == 'first'
          used_chain.shift while used_chain.length > 0 && !used_chain.first.blocks.has_key?(options[:name])
        elsif options[:node] == 'current'
          used_chain = context[:chain].dup
        end
        block_node = used_chain.first

        if !block_node || !block_node.blocks.has_key?(options[:name])
          if options[:notfound] == 'ignore'
            return ''
          elsif block_node
            raise Webgen::RenderError.new("No block named '#{options[:name]}' found in <#{block_node}>",
                                          self.class.name, context.dest_node,
                                          context.ref_node, (options[:line_nr_proc].call if options[:line_nr_proc]))
          else
            raise Webgen::RenderError.new("No node in the render chain has a block named '#{options[:name]}'",
                                          self.class.name, context.dest_node,
                                          context.ref_node, (options[:line_nr_proc].call if options[:line_nr_proc]))
          end
        end

        context.website.ext.item_tracker.add(dest_node, :node_content, block_node.alcn)
        tmp_context = block_node.render_block(options[:name], context.clone(:chain => used_chain, :dest_node => dest_node))
        tmp_context.content
      end

    end

  end
end
