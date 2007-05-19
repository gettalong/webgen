require 'redcloth'

module ContentProcessor

  # Handles content in Textile format using RedCloth.
  class Textile

    def process( content, context, options )
      RedCloth.new( content ).to_html
    rescue Exception => e
      raise "Textile to HTML conversion failed: #{e.message}"
    end

  end

end
