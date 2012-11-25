# -*- encoding: utf-8 -*-

require 'webgen/content_processor'
webgen_require 'redcloth', 'RedCloth'

module Webgen
  class ContentProcessor

    # Processes content in Textile format using the +redcloth+ library.
    module RedCloth

      # Convert the content in +context+ to HTML.
      def self.call(context)
        doc = ::RedCloth.new(context.content)
        doc.hard_breaks = context.website.config['content_processor.redcloth.hard_breaks']
        context.content = doc.to_html
        context
      end

    end

  end
end
