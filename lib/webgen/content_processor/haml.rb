# -*- encoding: utf-8 -*-

require 'webgen/content_processor'
webgen_require 'haml'

module Webgen::ContentProcessor

  # Processes content in Haml markup using the +haml+ library.
  class Haml

    # Convert the content in +haml+ markup to HTML.
    def call(context)
      context.content = ::Haml::Engine.new(context.content, :filename => context.ref_node.alcn).
        render(Object.new, :context => context)
      context
    rescue ::Haml::Error => e
      line = (e.line ? e.line + 1 : Webgen::Error.error_line(e))
      raise Webgen::RenderError.new(e, self.class.name, context.dest_node, context.ref_node, line)
    end

  end

end
