# -*- encoding: utf-8 -*-

module Webgen::ContentProcessor

  # Processes content in Haml markup using the +haml+ library.
  class Haml

    include Deprecated

    # Convert the content in +haml+ markup to HTML.
    def call(context)
      require 'haml'

      locals = {
        :context => context,
        :website => deprecate('website', 'context.website', context.website),
        :node => deprecate('node', 'context.node', context.content_node),
        :ref_node => deprecate('ref_node', 'context.ref_node', context.ref_node),
        :dest_node => deprecate('dest_node', 'context.dest_node', context.dest_node)
      }
      context.content = ::Haml::Engine.new(context.content, :filename => context.ref_node.alcn).
        render(Object.new, locals)
      context
    rescue ::Haml::Error => e
      raise Webgen::RenderError.new(e, self.class.name, context.dest_node.alcn, context.ref_node.alcn, (e.line + 1 if e.line))
    rescue Exception => e
      raise Webgen::RenderError.new(e, self.class.name, context.dest_node.alcn, context.ref_node.alcn)
    end

  end

end
