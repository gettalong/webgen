require 'erubis'

module Converter

  # Handles content in Textile format using RedCloth.
  class Erb

    def convert( content, context, options )
      Erubis::Eruby.new( content ).result( binding )
    rescue Exception => e
      log(:error) { "Error using ERB to process content: #{e.message}" }
      raise
    end

  end

end
