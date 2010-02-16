# -*- encoding: utf-8 -*-

require 'webgen/common'

module Webgen::ContentProcessor

  # Processes embedded Ruby statements.
  class Erb

    # Process the Ruby statements embedded in the content of +context+.
    def call(context)
      require 'erb'
      extend(ERB::Util)

      erb = ERB.new(context.content)
      erb.filename = context.ref_node.alcn
      context.content = erb.result(binding)
      context
    rescue Exception => e
      raise Webgen::RenderError.new(e, self.class.name, context.dest_node, context.ref_node, Webgen::Common.error_line(e))
    end

  end

end
