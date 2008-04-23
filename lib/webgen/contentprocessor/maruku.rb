module Webgen::ContentProcessor

  class Maruku

    include Webgen::WebsiteAccess

    def call(context)
      require 'maruku'
      context.content = ::Maruku.new(context.content).to_html
      context
    rescue Exception => e
      raise "Maruku to HTML conversion failed: #{e.message}"
    end

  end

end
