# -*- encoding: utf-8 -*-

module Webgen::ContentProcessor

  # Processes content in kramdown format (based on Markdown) using the +kramdown+ library.
  class Kramdown

    include Webgen::Loggable

    # Convert the content in +context+ to HTML.
    def call(context)
      require 'kramdown'
      require 'webgen/contentprocessor/kramdown/html'
      doc = ::Kramdown::Document.new(context.content,
                                     context.website.config['contentprocessor.kramdown.options'].merge(context.options['contentprocessor.kramdown.options'] || {}))
      context.content = KramdownHtmlConverter.convert(doc, context)
      doc.warnings.each do |warn|
        log(:warn) { "Warning while parsing <#{context.ref_node}> with kramdown: #{warn}" }
      end
      context
    rescue LoadError
      raise Webgen::LoadError.new('kramdown', self.class.name, context.dest_node, 'kramdown')
    end

  end

end
