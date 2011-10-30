# -*- encoding: utf-8 -*-

require 'webgen/content_processor'
webgen_require 'rdoc/markup/to_html', 'rdoc'

module Webgen
  class ContentProcessor

    # Converts content in RDoc markup (the native Ruby documentation format) to HTML. Needs the newer
    # RDoc implementation (version >= 2.4.x).
    module RDoc

      # Convert the content in RDoc markup to HTML.
      def self.call(context)
        context.content = ::RDoc::Markup::ToHtml.new.convert(context.content)
        context
      end

    end

  end
end
