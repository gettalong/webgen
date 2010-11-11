# -*- encoding: utf-8 -*-


require 'webgen/content_processor'
webgen_require 'builder'

module Webgen::ContentProcessor

  # Processes content that is valid Ruby to build an XML tree. This is done by using the +builder+
  # library.
  class Builder

    # Process the content of +context+ which needs to be valid Ruby code. The special variable +xml+
    # should be used to construct the XML content.
    def call(context)
      

      xml = ::Builder::XmlMarkup.new(:indent => 2)
      eval(context.content, binding, context.ref_node.alcn)
      context.content = xml.target!
      context
    rescue Exception => e
      raise Webgen::RenderError.new(e, self.class.name, context.dest_node,
                                    Webgen::Common.error_file(e), Webgen::Common.error_line(e))
    end

  end

end
