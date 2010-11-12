# -*- encoding: utf-8 -*-

require 'webgen/content_processor'
require 'erb'

module Webgen::ContentProcessor

  # Processes embedded Ruby statements.
  class Erb

    include ERB::Util

    # Process the Ruby statements embedded in the content of +context+.
    def call(context)
      erb = ERB.new(context.content)
      erb.filename = context.ref_node.alcn
      context.content = erb.result(binding)
      context
    end

  end

end
