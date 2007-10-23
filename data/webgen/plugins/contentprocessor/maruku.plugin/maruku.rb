require 'maruku'

module ContentProcessor

  # Handles content in Markdown+Extras format using Maruku.
  class Maruku

    def process( context )
      context.content = ::Maruku.new( context.content ).to_html
      context
    rescue Exception => e
      raise "Maruku to HTML conversion failed: #{e.message}"
    end

  end

end
