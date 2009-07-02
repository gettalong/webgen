# -*- encoding: utf-8 -*-

module Webgen::Tag

  # Create a link to a given (A)LCN.
  class Link

    include Webgen::Tag::Base

    # Return a HTML link to the given (A)LCN.
    def call(tag, body, context)
      if (dest_node = context.ref_node.resolve(param('tag.link.path').to_s, context.dest_node.lang))
        context.dest_node.node_info[:used_meta_info_nodes] << dest_node.alcn
        context.dest_node.link_to(dest_node, param('tag.link.attr').merge(:lang => context.content_node.lang))
      else
        log(:error) { "Could not resolve path '#{param('tag.link.path')}' in <#{context.ref_node.alcn}>" }
        context.dest_node.flag(:dirty)
        ''
      end
    rescue URI::InvalidURIError => e
      raise Webgen::RenderError.new("Error while parsing path '#{param('tag.link.path')}': #{e.message}",
                                    self.class.name, context.dest_node, context.ref_node)
    end

  end

end
