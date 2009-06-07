# -*- encoding: utf-8 -*-

module Webgen::ContentProcessor

  # Processes embedded Ruby statements.
  class Erb

    include Deprecated

    # Process the Ruby statements embedded in the content of +context+.
    def call(context)
      require 'erb'

      website = deprecate('website', 'context.website', context.website)
      node = deprecate('node', 'context.node', context.content_node)
      ref_node = deprecate('ref_node', 'context.ref_node', context.ref_node)
      dest_node = deprecate('dest_node', 'context.dest_node', context.dest_node)

      erb = ERB.new(context.content)
      erb.filename = context.ref_node.alcn
      context.content = erb.result(binding)
      context
    rescue Exception => e
      raise RuntimeError, "Erb processing failed in <#{context.ref_node.alcn}>: #{e.message}", e.backtrace
    end

  end

end
