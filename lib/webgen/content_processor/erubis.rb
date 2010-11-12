# -*- encoding: utf-8 -*-

require 'webgen/content_processor'
webgen_require 'erubis'

module Webgen::ContentProcessor

  # Processes embedded Ruby statements with the +erubis+ library.
  class Erubis

    # Including Erubis because of problem with resolving Erubis::XmlHelper et al
    include ::Erubis

    # Process the Ruby statements embedded in the content of +context+.
    def call(context)
      options = context.website.config['contentprocessor.erubis.options']
      if context[:block]
        use_pi = context[:block].options['erubis_use_pi']
        context[:block].options.select {|k,v| k =~ /^erubis_/}.
          each {|k,v| options[k.sub(/^erubis_/, '').to_sym] = v }
      end
      erubis = if (!use_pi.nil? && use_pi) || (use_pi.nil? && context.website.config['contentprocessor.erubis.use_pi'])
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
