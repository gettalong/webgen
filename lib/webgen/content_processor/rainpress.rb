# -*- encoding: utf-8 -*-

require 'webgen/content_processor'
require 'webgen/vendor/rainpress'

module Webgen
  class ContentProcessor

    # Minifies CSS files.
    module Rainpress

      # Process the content of +context+ with Rainpress (a CSS minifier).
      def self.call(context)
        context.content = ::Rainpress.compress(context.content, context.website.config['content_processor.rainpress.options'])
        context
      end

    end

  end
end
