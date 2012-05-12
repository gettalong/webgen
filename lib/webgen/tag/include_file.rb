# -*- encoding: utf-8 -*-

require 'cgi'

module Webgen
  class Tag

    # Includes a file verbatim and optionally escapes all special HTML characters and/or processes
    # webgen tags in it.
    module IncludeFile

      # Include the specified file verbatim in the output, optionally escaping special HTML characters
      # and/or processing tags in it.
      def self.call(tag, body, context)
        filename = context[:config]['tag.include_file.filename']
        filename = File.join(context.website.directory, filename) unless filename =~ /^(\/|\w:)/
        if !File.exists?(filename)
          raise Webgen::RenderError.new("File '#{filename}' cannot be included because it does not exist",
                                        self.name, context.dest_node, context.ref_node)
        end

        content = File.read(filename)
        content = CGI::escapeHTML(content) if context[:config]['tag.include_file.escape_html']
        context.website.ext.item_tracker.add(context.dest_node, :file, filename)

        [content, context[:config]['tag.include_file.process_output']]
      end

    end

  end
end
