# -*- encoding: utf-8 -*-

require 'webgen/content_processor'

module Webgen
  class ContentProcessor

    # Processes special webgen tags to provide dynamic content.
    #
    # webgen tags are an easy way to add dynamically generated content to websites, for example menus
    # or breadcrumb trails.
    module Tags

      # Replace all webgen tags in the content of +context+ with the rendered content.
      def self.call(context)
        context.website.ext.tag.replace_tags(context.content) do |tag, params, body|
          context.website.logger.debug do
            "Replacing tag #{tag} with data #{params.inspect} and body '#{body}' in <#{context.ref_node}>"
          end
          context.website.ext.tag.call(tag, params, body, context)
        end
        context
      end

    end

  end
end
