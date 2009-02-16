# -*- encoding: utf-8 -*-

module Webgen::Tag

  # Create a link to a given (A)LCN.
  class Link

    include Webgen::Tag::Base

    # Return a HTML link to the given (A)LCN.
    def call(tag, body, context)
      if (dest_node = context.ref_node.resolve(param('tag.link.path'), context.dest_node.lang))
        context.dest_node.link_to(dest_node, param('tag.link.attr').merge(:lang => context.content_node.lang))
      else
        raise ArgumentError, 'Resolving of path failed'
      end
    rescue ArgumentError, URI::InvalidURIError => e
      log(:error) { "Could not link to path '#{param('tag.link.path')}' in <#{context.ref_node.absolute_lcn}>: #{e.message}" }
      context.dest_node.flag(:dirty)
      ''
    end

  end

end
