# -*- encoding: utf-8 -*-

require 'webgen/content_processor'
webgen_require 'rdiscount'

module Webgen
  class ContentProcessor

    # Processes content in Markdown markup with the fast +rdiscount+ library.
    module RDiscount

      # Convert the content in +context+ to HTML.
      def self.call(context)
        context.content = ::RDiscount.new(context.content).to_html
        context
      end

    end

  end
end
