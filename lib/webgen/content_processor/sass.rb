# -*- encoding: utf-8 -*-

require 'webgen/content_processor'
webgen_require 'sass'

module Webgen
  class ContentProcessor

    # Processes content in Sass markup (used for writing CSS files).
    module Sass

      # Convert the content in +sass+ markup to CSS.
      def self.call(context)
        context.content = ::Sass::Engine.new(context.content, :filename => context.ref_node.alcn).render
        context
      rescue ::Sass::SyntaxError => e
        raise Webgen::RenderError.new(e, self.class.name, context.dest_node, nil, (e.sass_line if e.sass_line))
      end

    end

  end
end
