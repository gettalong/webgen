module Webgen::ContentProcessor

  # Processes content that is valid Ruby to build an XML tree. This is done by using the +builder+
  # library.
  class Builder

    # Process the content of +context+ which needs to be valid Ruby code. The special variable +xml+
    # should be used to construct the XML content.
    def call(context)
      require 'builder'

      node = context.content_node
      ref_node = context.ref_node
      dest_node = context.dest_node

      xml = ::Builder::XmlMarkup.new(:indent => 2)
      eval(context.content, binding, context.ref_node.absolute_lcn)
      context.content = xml.target!
      context
    rescue Exception => e
      raise RuntimeError, "Error using Builder to generate XML: #{e.message}", e.backtrace
    end

  end

end
