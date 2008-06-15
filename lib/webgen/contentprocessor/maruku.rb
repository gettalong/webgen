module Webgen::ContentProcessor

  class Maruku

    def call(context)
      require 'maruku'
      context.content = ::Maruku.new(context.content, :on_error => :raise).to_html
      context
    rescue Exception => e
      raise "Maruku to HTML conversion failed: #{e.message}"
    end

  end

end
