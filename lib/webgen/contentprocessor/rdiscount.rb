# -*- encoding: utf-8 -*-

module Webgen::ContentProcessor

  # Processes content in Markdown markup with the fast +rdiscount+ library.
  class RDiscount

    # Convert the content in +context+ to HTML.
    def call(context)
      require 'rdiscount'
      context.content = ::RDiscount.new(context.content).to_html
      context
    rescue LoadError
      raise Webgen::LoadError.new('rdiscount', self.class.name, context.dest_node, 'rdiscount')
    end

  end

end
