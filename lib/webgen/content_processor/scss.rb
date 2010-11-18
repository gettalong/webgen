# -*- encoding: utf-8 -*-

require 'webgen/content_processor'
webgen_require 'sass', 'haml'

module Webgen
  class ContentProcessor

    # Processes content in sassy CSS markup (used for writing CSS files) using the +haml+ library.
    class Scss

      # Convert the content in +scss+ markup to CSS.
      def call(context)
        context.content = ::Sass::Engine.new(context.content, :filename => context.ref_node.alcn, :syntax => :scss).render
        context
      rescue ::Sass::SyntaxError => e
        raise Webgen::RenderError.new(e, self.class.name, context.dest_node, context.ref_node, (e.sass_line if e.sass_line))
      end

    end

  end
end
