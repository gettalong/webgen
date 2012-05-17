# -*- encoding: utf-8 -*-

webgen_require 'coderay'

module Webgen
  class Tag

    # Provides syntax highlighting via the +coderay+ library.
    module Coderay

      # Highlight the body of the block.
      def self.call(tag, body, context)
        config = context[:config]

        options = {}
        if config['tag.coderay.css'].to_s == 'other'
          options[:css] = :class
        elsif config['tag.coderay.css'].to_s == 'class'
          options[:css] = :class
          context.html_head.link_file(:css, '/stylesheets/coderay-default.css')
        else
          options[:css] = :style
        end
        options.merge!(:wrap => config['tag.coderay.wrap'].to_sym,
                       :line_numbers => (config['tag.coderay.line_numbers'] ? :inline : nil),
                       :line_number_start => config['tag.coderay.line_number_start'],
                       :tab_width => config['tag.coderay.tab_width'],
                       :bold_every => config['tag.coderay.bold_every'])

        if config['tag.coderay.process_body']
          body = context.website.ext.content_processor.call('tags', context.clone(:content => body)).content
        end
        CodeRay.scan(body, config['tag.coderay.lang'].to_sym).html(options)
      end

    end

  end
end
