# -*- encoding: utf-8 -*-

require 'kramdown'

module Webgen::ContentProcessor

  class KramdownHtmlConverter < ::Kramdown::Converter::Html

    def initialize(doc, context) #:nodoc:
      super(doc)
      @context = context
      @do_convert = if context.options.has_key?('contentprocessor.kramdown.handle_links')
                      context.options['contentprocessor.kramdown.handle_links']
                    else
                      context.website.config['contentprocessor.kramdown.handle_links']
                    end
    end

    # Convert the Kramdown document +doc+ to HTML using the webgen +context+ object.
    def self.convert(doc, context)
      new(doc, context).convert(doc.tree)
    end

    def convert_a(el, indent, opts)
      el.options[:attr]['href'] = @context.tag('relocatable', {'path' => el.options[:attr]['href']}) if @do_convert
      "<a#{options_for_element(el)}>#{inner(el, indent, opts)}</a>"
    end

    def convert_img(el, indent, opts)
      el.options[:attr]['src'] = @context.tag('relocatable', {'path' => el.options[:attr]['src']}) if @do_convert
      "<img#{options_for_element(el)} />"
    end

  end

end
