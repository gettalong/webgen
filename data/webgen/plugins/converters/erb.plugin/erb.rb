require 'erb'

module Converter

  # Uses the builtin ERB to process the content.
  class Erb

    def convert( content, context, options )
      ERB.new( content ).result( binding )
    rescue Exception => e
      log(:error) { "Error using ERB to process content: #{e.message}" }
      raise
    end

  end

end
