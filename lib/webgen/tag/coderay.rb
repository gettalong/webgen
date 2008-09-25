module Webgen::Tag

  # Provides syntax highlighting via the +coderay+ library.
  class Coderay

    include Webgen::Tag::Base
    include Webgen::WebsiteAccess

    # Highlight the body of the block.
    def call(tag, body, context)
      require 'coderay'
      options = {
        :css => :style,
        :wrap => param('tag.coderay.wrap').to_sym,
        :line_numbers => (param('tag.coderay.line_numbers') ? :inline : nil),
        :line_number_start => param('tag.coderay.line_number_start'),
        :tab_width => param('tag.coderay.tab_width'),
        :bold_every => param('tag.coderay.bold_every')
      }

      if param('tag.coderay.process_body')
        body = website.blackboard.invoke(:content_processor, 'tags').call(context.clone(:content => body)).content
      end
      CodeRay.scan(body, param('tag.coderay.lang').to_sym).html(options)
    end

  end

end
