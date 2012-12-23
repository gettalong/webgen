# -*- encoding: utf-8 -*-
require 'cgi'

module Webgen
  class Tag

    # Provides easy access to the meta information of a node.
    module MetaInfo

      # Treat +tag+ as a meta information key and return its value from the content node.
      def self.call(tag, body, context)
        tag = context[:config]['tag.meta_info.mi'] if tag == 'meta_info'
        output = ''
        if tag == 'lang'
          output = context.content_node.lang
        elsif context.content_node[tag]
          output = context.content_node[tag].to_s
          output = CGI::escapeHTML(output) if context[:config]['tag.meta_info.escape_html']
        else
          context.website.logger.error do
            ["No meta info key '#{tag}' found in <#{context.content_node}> (referenced in <#{context.ref_node}>)",
             "Add the meta info key '#{tag}' to <#{context.content_node}> or remove the" +
             " reference in <#{context.ref_node}> to fix this error."]
          end
        end
        output
      end

    end

  end
end
