# -*- encoding: utf-8 -*-

require 'webgen/content_processor'
webgen_require 'erubis'

module Webgen
  class ContentProcessor

    # Processes embedded Ruby statements with the +erubis+ library.
    module Erubis

      class CompatibleEruby < ::Erubis::Eruby #:nodoc:
        include ::Erubis::ErboutEnhancer
        include ::Erubis::PercentLineEnhancer
      end

      class CompatiblePIEruby < ::Erubis::PI::Eruby #:nodoc:
        include ::Erubis::ErboutEnhancer
        include ::Erubis::PercentLineEnhancer
      end

      # Including Erubis because of problem with resolving Erubis::XmlHelper et al
      include ::Erubis
      extend ::Erubis::XmlHelper

      # Process the Ruby statements embedded in the content of +context+.
      def self.call(context)
        options = context.website.config['content_processor.erubis.options']
        erubis = if context.website.config['content_processor.erubis.use_pi']
                   CompatiblePIEruby.new(context.content, options)
                 else
                   CompatibleEruby.new(context.content, options)
                 end
        erubis.filename = context.ref_node.alcn
        context.content = erubis.result(binding)
        context
      end

    end

  end
end
