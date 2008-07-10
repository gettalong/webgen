module Webgen::ContentProcessor

  # Processes embedded Ruby statements.
  class Erb

    # Process the Ruby statements embedded in the content of +context+.
    def call(context)
      require 'erb'

      node = context.content_node
      ref_node = context.ref_node
      dest_node = context.dest_node

      erb = ERB.new(context.content)
      erb.filename = context.ref_node.node_info[:src]
      context.content = erb.result(binding)
      context
    rescue Exception => e
      raise "Erb processing failed: #{e.message}"
    end

  end

end
