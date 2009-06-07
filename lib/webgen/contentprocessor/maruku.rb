# -*- encoding: utf-8 -*-

module Webgen::ContentProcessor

  # Processes content in Markdown format using the +maruku+ library.
  class Maruku

    # Convert the content in +context+ to HTML.
    def call(context)
      require 'maruku'
      $uid = 0 #fix for invalid fragment ids on second run
      context.content = ::Maruku.new(context.content, :on_error => :raise).to_html
      context
    rescue Exception => e
      raise RuntimeError, "Maruku to HTML conversion failed for <#{context.ref_node.alcn}>: #{e.message}", e.backtrace
    end

  end

end
