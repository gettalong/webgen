require 'haml'

module ContentProcessor

  # Handles content in Haml markup using the haml gem.
  class Haml

    def process( context )
      options = {
        :locals => {
          :context => context,
          :node => context.node,
          :ref_node => context.ref_node
        },
        :filename => context.ref_node.absolute_lcn
      }
      context.content = ::Haml::Engine.new( context.content, options ).render
      context
    rescue Exception => e
      raise "Error converting Haml text to HTML: #{e.message}"
    end

  end

end
