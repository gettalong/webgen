# -*- encoding: utf-8 -*-

require 'webgen/common'

module Webgen::ContentProcessor

  # Processes content that is valid Ruby to build an XML tree. This is done by using the +builder+
  # library.
  class Builder

    # Process the content of +context+ which needs to be valid Ruby code. The special variable +xml+
    # should be used to construct the XML content.
    def call(context)
      require 'builder'

      xml = ::Builder::XmlMarkup.new(:indent => 2)
      eval(context.content, binding, context.ref_node.alcn)
      context.content = xml.target!
      context
    rescue LoadError
      raise Webgen::LoadError.new('builder', self.class.name, context.dest_node, 'builder')
    rescue Exception => e
      raise Webgen::RenderError.new(e, self.class.name, context.dest_node, context.ref_node, Webgen::Common.error_line(e))
    end

  end

end
