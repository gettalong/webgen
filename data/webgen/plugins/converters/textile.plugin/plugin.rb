#load_optional_part( 'content-converter-textile',
#                    :needed_gems => ['redcloth'],
#                    :error_msg => "Textile not available as content format as RedCloth could not be loaded",
#                    :info => "Textile can be used as content format" ) do

require 'redcloth'

module Converter

  # Handles content in Textile format using RedCloth.
  class Textile

    def convert( content, context, options )
      RedCloth.new( content ).to_html
    rescue Exception => e
      log(:error) { "Error converting Textile text to HTML: #{e.message}" }
      content
    end

  end

end

#end
