# -*- encoding: utf-8 -*-

require 'webgen/content_processor'
webgen_require 'rdiscount'

module Webgen::ContentProcessor

  # Processes content in Markdown markup with the fast +rdiscount+ library.
  class RDiscount

    # Convert the content in +context+ to HTML.
    def call(context)
      context.content = ::RDiscount.new(context.content).to_html
      context
    end

  end

end
