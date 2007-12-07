require 'sass'

module ContentProcessor

  # Handles content in Sass markup using the haml gem.
  class Sass

    def process( context )
      options = {
        :filename => context.ref_node.absolute_lcn
      }
      context.content = ::Sass::Engine.new( context.content, options ).render
      context
    rescue Exception => e
      raise "Error converting Sass text to HTML: #{e.message}"
    end

  end

end
