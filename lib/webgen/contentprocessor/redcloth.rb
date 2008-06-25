module Webgen::ContentProcessor

  # Processes content in Textile format using the +redcloth+ library.
  class RedCloth

    # Convert the content in +context+ to HTML.
    def call(context)
      require 'redcloth'
      context.content = ::RedCloth.new(context.content).to_html
      context
    end

  end

end
