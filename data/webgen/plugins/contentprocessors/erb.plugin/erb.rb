require 'erb'

module ContentProcessor

  # Uses the builtin ERB to process the content.
  class Erb

    def process( content, context, options )
      ERB.new( content ).result( binding )
    rescue Exception => e
      raise "Processing with ERB failed: #{e.message}"
    end

  end

end
