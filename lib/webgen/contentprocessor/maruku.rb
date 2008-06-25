module Webgen::ContentProcessor

  # Processes content in Markdown format using the +maruku+ library.
  class Maruku

    # Convert the content in +context+ to HTML.
    def call(context)
      require 'maruku'
      context.content = ::Maruku.new(context.content, :on_error => :raise).to_html
      context
    rescue Exception => e
      raise "Maruku to HTML conversion failed: #{e.message}"
    end

  end

end
