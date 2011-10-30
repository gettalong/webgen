# -*- encoding: utf-8 -*-

require 'webgen/content_processor'
webgen_require 'erubis'

module Webgen
  class ContentProcessor

    # Processes embedded Ruby statements with the +erubis+ library.
    module Erubis

      # Including Erubis because of problem with resolving Erubis::XmlHelper et al
      include ::Erubis

      # Process the Ruby statements embedded in the content of +context+.
      def self.call(context)
        options = context.website.config['content_processor.erubis.options']
        erubis = if context.website.config['content_processor.erubis.use_pi']
                   ::Erubis::PI::Eruby.new(context.content, options)
                 else
                   ::Erubis::Eruby.new(context.content, options)
                 end
        erubis.filename = context.ref_node.alcn
        context.content = erubis.result(binding)
        context
      end

    end

  end
end
