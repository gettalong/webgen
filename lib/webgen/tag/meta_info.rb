# -*- encoding: utf-8 -*-
require 'cgi'

module Webgen
  class Tag

    # Provides easy access to the meta information of a node.
    module MetaInfo

      # Return the meta information key specified in +tag+ of the content node.
      def self.call(tag, body, context)
        output = ''
        if tag == 'lang'
          output = context.content_node.lang
        elsif context.content_node[tag]
          output = context.content_node[tag].to_s
          output = CGI::escapeHTML(output) if context[:config]['tag.meta_info.escape_html']
        else
          context.website.logger.error do
            "No meta info key '#{tag}' found in <#{context.content_node}> (referenced in <#{context.ref_node}>)"
          end
        end
        output
      end

    end

  end
end
