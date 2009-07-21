# -*- encoding: utf-8 -*-

module Webgen::ContentProcessor

  # Processes embedded Ruby statements.
  class Erb

    include Deprecated

    # Process the Ruby statements embedded in the content of +context+.
    def call(context)
      require 'erb'
      extend(ERB::Util)

      website = deprecate('website', 'context.website', context.website)
      node = deprecate('node', 'context.node', context.content_node)
      ref_node = deprecate('ref_node', 'context.ref_node', context.ref_node)
      dest_node = deprecate('dest_node', 'context.dest_node', context.dest_node)

      erb = ERB.new(context.content)
      erb.filename = context.ref_node.alcn
      context.content = erb.result(binding)
      context
    rescue Exception => e
      line = (e.is_a?(::SyntaxError) ? e.message : e.backtrace[0]).scan(/:(\d+)/).first.first.to_i rescue nil
      raise Webgen::RenderError.new(e, self.class.name, context.dest_node.alcn, context.ref_node.alcn, line)
    end

  end

end
