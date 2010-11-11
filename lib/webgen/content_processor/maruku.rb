# -*- encoding: utf-8 -*-

require 'rexml/parsers/baseparser'

class REXML::Parsers::BaseParser

  alias :"old_stream=" :"stream="

  def stream=(source)
    self.old_stream=(source)
    @nsstack << Set.new(['webgen'])
  end

end


module Webgen::ContentProcessor

  # Processes content in Markdown format using the +maruku+ library.
  class Maruku

    # Convert the content in +context+ to HTML.
    def call(context)
      require 'maruku'
      $uid = 0 #fix for invalid fragment ids on second run
      context.content = ::Maruku.new(context.content, :on_error => :raise).to_html
      context
    rescue LoadError
      raise Webgen::LoadError.new('maruku', self.class.name, context.dest_node, 'maruku')
    rescue Exception => e
      raise Webgen::RenderError.new(e, self.class.name, context.dest_node, context.ref_node)
    end

  end

end
