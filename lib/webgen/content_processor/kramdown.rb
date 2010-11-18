# -*- encoding: utf-8 -*-

require 'webgen/content_processor'
webgen_require 'kramdown'
require 'webgen/contentprocessor/kramdown/html'

module Webgen
  class ContentProcessor

    # Processes content in kramdown format (based on Markdown) using the +kramdown+ library.
    class Kramdown

      include Webgen::Loggable

      # Convert the content in +context+ to HTML.
      def call(context)
        doc = ::Kramdown::Document.new(context.content,
                                       context.website.config['contentprocessor.kramdown.options'].merge(context.options['contentprocessor.kramdown.options'] || {}))
        context.content = KramdownHtmlConverter.convert(doc.root, doc.options, context)
        doc.warnings.each do |warn|
          log(:warn) { "Warning while parsing <#{context.ref_node}> with kramdown: #{warn}" }
        end
        context
      end

    end

  end
end
