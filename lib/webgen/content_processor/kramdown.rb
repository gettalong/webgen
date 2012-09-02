# -*- encoding: utf-8 -*-

require 'webgen/content_processor'
webgen_require 'kramdown'

module Webgen
  class ContentProcessor

    # Processes content in kramdown format (based on Markdown) using the +kramdown+ library.
    module Kramdown

      class CustomHtmlConverter < ::Kramdown::Converter::Html #:nodoc:
        public_class_method(:new)

        def initialize(root, options, context)
          super(root, options)
          @context = context
          @do_convert = context.website.config['content_processor.kramdown.handle_links']
        end

        def convert_a(el, indent)
          el.attr['href'] = @context.tag('relocatable', {'path' => el.attr['href']}) if @do_convert
          super
        end

        def convert_img(el, indent)
          el.attr['src'] = @context.tag('relocatable', {'path' => el.attr['src']}) if @do_convert
          super
        end

      end

      # Convert the content in +context+ to HTML.
      def self.call(context)
        doc = ::Kramdown::Document.new(context.content, context.website.config['content_processor.kramdown.options'])
        context.content = CustomHtmlConverter.new(doc.root, doc.options, context).convert(doc.root)
        doc.warnings.each do |warn|
          context.website.logger.warn { "kramdown warning while parsing <#{context.ref_node}>: #{warn}" }
        end
        context
      end

    end

  end
end
