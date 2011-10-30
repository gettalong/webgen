# -*- encoding: utf-8 -*-

require 'webgen/content_processor'
webgen_require 'haml'

module Webgen
  class ContentProcessor

    # Processes content in Haml markup using the +haml+ library.
    module Haml

      # Convert the content in +haml+ markup to HTML.
      def self.call(context)
        context.content = ::Haml::Engine.new(context.content, :filename => context.ref_node.alcn).
          render(Object.new, :context => context)
        context
      rescue ::Haml::Error => e
        line = (e.line ? e.line + 1 : Webgen::Error.error_line(e))
        raise Webgen::RenderError.new(e, self.class.name, context.dest_node, nil, line)
      end

    end

  end
end
