module Webgen::ContentProcessor

  class RedCloth

    def call(context)
      require 'redcloth'
      context.content = ::RedCloth.new(context.content).to_html
      context
    end

  end

end
