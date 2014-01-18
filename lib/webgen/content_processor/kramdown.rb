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
          @ignore_fragments = context.website.config['content_processor.kramdown.ignore_unknown_fragments']
        end

        def convert_a(el, indent)
          el.attr['href'] = @context.tag('relocatable', {'path' => el.attr['href'],
                                           'ignore_unknown_fragment' => @ignore_fragments}) if @do_convert
          super
        end

        def convert_img(el, indent)
          el.attr['src'] = @context.tag('relocatable', {'path' => el.attr['src'],
                                          'ignore_unknown_fragment' => @ignore_fragments}) if @do_convert
          super
        end

      end

      class ::Kramdown::Parser::WebgenKramdown < ::Kramdown::Parser::Kramdown #:nodoc:

        LINK_DEFS_CACHE = {}

        # Caching already normalized link definitions because this is potentially an O(n*m)
        # operation where n...number of link definitions, m...number of invocations.
        def update_link_definitions(link_defs)
          link_defs.each do |k, v|
            @link_defs[LINK_DEFS_CACHE[k] ||= normalize_link_id(k)] = v
          end
        end

      end

      # Convert the content in +context+ to HTML.
      def self.call(context)
        options = context.website.config['content_processor.kramdown.options'].dup
        options[:link_defs] = context.website.ext.link_definitions.merge(options[:link_defs] || {})
        options[:input] = 'WebgenKramdown'
        doc = ::Kramdown::Document.new(context.content, options)
        context.content = CustomHtmlConverter.new(doc.root, doc.options, context).convert(doc.root)
        context.content.encode!(doc.root.options[:encoding])
        doc.warnings.each do |warn|
          context.website.logger.warn { "kramdown warning while parsing <#{context.ref_node}>: #{warn}" }
        end
        context
      end

    end

  end
end
