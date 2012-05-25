# -*- encoding: utf-8 -*-

require 'webgen/content_processor'

module Webgen
  class ContentProcessor

    # Processes the content that is valid Ruby to generate new content.
    module Ruby

      # Process the content of +context+ which needs to be valid Ruby code.
      def self.call(context)
        eval(context.content, binding, context.ref_node.alcn)
        context
      end

    end

  end
end
