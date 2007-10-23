require 'redcloth'

module ContentProcessor

  # Handles content in Textile format using RedCloth.
  class Textile

    def process( context )
      context.content = RedCloth.new( context.content ).to_html
      context
    rescue Exception => e
      raise "Textile to HTML conversion failed: #{e.message}"
    end

  end

end
