module Webgen::ContentProcessor

  # Converts content in RDoc markup (the native Ruby documentation format) to HTML. Needs the newer
  # RDoc implementation provided as +rdoc+ gem!
  class RDoc

    # Convert the content in RDoc markup to HTML.
    def call(context)
      require 'rdoc/markup/to_html'

      context.content = ::RDoc::Markup::ToHtml.new.convert(context.content)
      context
    end

  end

end
