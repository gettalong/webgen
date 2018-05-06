# -*- encoding: utf-8 -*-

require 'webgen/content_processor'
webgen_require 'cssminify'

module Webgen
  class ContentProcessor

    # Minifies CSS files.
    module CSSMinify

      # Process the content of +context+ with CSSMinify (a CSS minifier).
      def self.call(context)
        context.content = ::CSSminify.compress(context.content)
        context
      end

    end

  end
end
