require 'maruku'

module ContentProcessor

  # Handles content in Markdown+Extras format using Maruku.
  class Maruku

    def process( content, context, options )
      ::Maruku.new( content ).to_html
    rescue Exception => e
      raise "Maruku to HTML conversion failed: #{e.message}"
    end

  end

end
