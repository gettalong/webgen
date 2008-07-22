module Webgen::ContentProcessor

  # Processes content in Sass markup (used for writing CSS files) using the +haml+ library.
  class Sass

    # Convert the content in +sass+ markup to CSS.
    def call(context)
      require 'sass'

      context.content = ::Sass::Engine.new(context.content, :filename => context.ref_node.absolute_lcn).render
      context
    rescue Exception => e
      raise "Error converting Sass markup to CSS: #{e.message}"
    end

  end

end
