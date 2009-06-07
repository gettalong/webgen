# -*- encoding: utf-8 -*-

module Webgen::ContentProcessor

  # Processes embedded Ruby statements with the +erubis+ library.
  class Erubis

    include Deprecated

    # Process the Ruby statements embedded in the content of +context+.
    def call(context)
      require 'erubis'
      # including Erubis because of problem with resolving Erubis::XmlHelper et al
      self.class.class_eval "include ::Erubis"

      website = deprecate('website', 'context.website', context.website)
      node = deprecate('node', 'context.node', context.content_node)
      ref_node = deprecate('ref_node', 'context.ref_node', context.ref_node)
      dest_node = deprecate('dest_node', 'context.dest_node', context.dest_node)

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
    rescue Exception => e
      raise RuntimeError, "Erubis processing failed in <#{context.ref_node.alcn}>: #{e.message}", e.backtrace
    end

  end

end
