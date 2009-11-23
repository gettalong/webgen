# -*- encoding: utf-8 -*-

require 'kramdown'

module Webgen::ContentProcessor

  class KramdownHtmlConverter < ::Kramdown::Converter::Html

    def initialize(doc, context) #:nodoc:
      super(doc)
      @context = context
      @do_convert = context.website.config['contentprocessor.kramdown.handle_links']
    end

    # Convert the Kramdown document +doc+ to HTML using the webgen +context+ object.
    def self.convert(doc, context)
      new(doc, context).convert(doc.tree)
    end

    def convert_a(el, inner, indent)
      el.options[:attr]['href'] = @context.tag('relocatable', {'path' => el.options[:attr]['href']}) if @do_convert
      "<a#{options_for_element(el)}>#{inner}</a>"
    end

    def convert_img(el, inner, indent)
      el.options[:attr]['src'] = @context.tag('relocatable', {'path' => el.options[:attr]['src']}) if @do_convert
      "<img#{options_for_element(el)} />"
    end

  end

end
