# -*- encoding: utf-8 -*-

require 'webgen/content_processor'
require 'erb'

module Webgen
  class ContentProcessor

    # Processes embedded Ruby statements.
    module Erb

      extend ERB::Util

      # Process the Ruby statements embedded in the content of +context+.
      def self.call(context)
        erb = ERB.new(context.content, nil, context.website.config['content_processor.erb.trim_mode'])
        erb.filename = context.ref_node.alcn
        context.content = erb.result(binding)
        context
      end

    end

  end
end
