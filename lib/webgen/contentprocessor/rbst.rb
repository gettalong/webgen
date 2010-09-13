# -*- encoding: utf-8 -*-

module Webgen::ContentProcessor

  # Processes content in reStructuredText format using the +RbST+ library.
  class RbST

    include Webgen::Loggable

    # Convert the content in +context+ to HTML.
    def call(context)
      require 'rbst'
        context.content = ::RbST.new(context.content).to_html
        context
      rescue LoadError
        raise Webgen::LoadError.new('rbst/markup/to_html', self.class.name, context.dest_node, 'rbst')
    end

  end

end
