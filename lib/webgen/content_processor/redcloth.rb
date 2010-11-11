# -*- encoding: utf-8 -*-

module Webgen::ContentProcessor

  # Processes content in Textile format using the +redcloth+ library.
  class RedCloth

    # Convert the content in +context+ to HTML.
    def call(context)
      require 'redcloth'
      doc = ::RedCloth.new(context.content)
      doc.hard_breaks = context.website.config['contentprocessor.redcloth.hard_breaks']
      context.content = doc.to_html
      context
    rescue LoadError
      raise Webgen::LoadError.new('redcloth', self.class.name, context.dest_node, 'RedCloth')
    end

  end

end
