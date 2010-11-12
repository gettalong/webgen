# -*- encoding: utf-8 -*-

require 'webgen/content_processor'
webgen_require 'redcloth', 'RedCloth'

module Webgen::ContentProcessor

  # Processes content in Textile format using the +redcloth+ library.
  class RedCloth

    # Convert the content in +context+ to HTML.
    def call(context)
      doc = ::RedCloth.new(context.content)
      doc.hard_breaks = context.website.config['contentprocessor.redcloth.hard_breaks']
      context.content = doc.to_html
      context
    end

  end

end
