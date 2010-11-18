# -*- encoding: utf-8 -*-

require 'kramdown'

module Webgen
  class ContentProcessor

    class KramdownHtmlConverter < ::Kramdown::Converter::Html

      def initialize(root, options, context) #:nodoc:
        super(root, options)
        @context = context
        @do_convert = if context.options.has_key?('contentprocessor.kramdown.handle_links')
                        context.options['contentprocessor.kramdown.handle_links']
                      else
                        context.website.config['contentprocessor.kramdown.handle_links']
                      end
      end

      # Convert the element tree under +root+ to HTML using the webgen +context+ object.
      def self.convert(root, options, context)
        new(root, options, context).convert(root)
      end

      def convert_a(el, indent)
        el.attr['href'] = @context.tag('relocatable', {'path' => el.attr['href']}) if @do_convert
        "<a#{html_attributes(el.attr)}>#{inner(el, indent)}</a>"
      end

      def convert_img(el, indent)
        el.attr['src'] = @context.tag('relocatable', {'path' => el.attr['src']}) if @do_convert
        "<img#{html_attributes(el.attr)} />"
      end

    end

  end
end
