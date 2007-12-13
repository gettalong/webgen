require 'rdoc/markup/simple_markup'
require 'rdoc/markup/simple_markup/to_html'

module ContentProcessor

  # Handles text in RDoc format.
  class RDoc

    def initialize
      @processor = SM::SimpleMarkup.new
      @formatter = SM::ToHtml.new
    end

    def process( context )
      context.content = @processor.convert( context.content, @formatter )
      context
    rescue Exception => e
      raise "Error converting RDOC text to HTML: {e.message}"
    end

  end

end
