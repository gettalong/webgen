# -*- encoding: utf-8 -*-

module Webgen::ContentProcessor

  # Processes content in Sass markup (used for writing CSS files) using the +haml+ library.
  class Sass

    # Convert the content in +sass+ markup to CSS.
    def call(context)
      require 'sass'

      context.content = ::Sass::Engine.new(context.content, :filename => context.ref_node.alcn).render
      context
    rescue ::Sass::SyntaxError => e
      raise Webgen::RenderError.new(e, self.class.name, context.dest_node.alcn, context.ref_node.alcn, (e.sass_line if e.sass_line))
    end

  end

end
