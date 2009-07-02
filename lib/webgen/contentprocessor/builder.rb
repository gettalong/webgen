# -*- encoding: utf-8 -*-

module Webgen::ContentProcessor

  # Processes content that is valid Ruby to build an XML tree. This is done by using the +builder+
  # library.
  class Builder

    include Deprecated

    # Process the content of +context+ which needs to be valid Ruby code. The special variable +xml+
    # should be used to construct the XML content.
    def call(context)
      require 'builder'

      website = deprecate('website', 'context.website', context.website)
      node = deprecate('node', 'context.node', context.content_node)
      ref_node = deprecate('ref_node', 'context.ref_node', context.ref_node)
      dest_node = deprecate('dest_node', 'context.dest_node', context.dest_node)

      xml = ::Builder::XmlMarkup.new(:indent => 2)
      eval(context.content, binding, context.ref_node.alcn)
      context.content = xml.target!
      context
    rescue Exception => e
      line = (e.is_a?(::SyntaxError) ? e.message : e.backtrace[0]).scan(/:(\d+)/).first.first.to_i
      raise Webgen::RenderError.new(e, self.class.name, context.dest_node.alcn, context.ref_node.alcn, line)
    end

  end

end
