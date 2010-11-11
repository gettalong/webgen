# -*- encoding: utf-8 -*-

require 'webgen/common'

module Webgen::ContentProcessor

  # Processes embedded Ruby statements with the +erubis+ library.
  class Erubis

    # Process the Ruby statements embedded in the content of +context+.
    def call(context)
      require 'erubis'
      # including Erubis because of problem with resolving Erubis::XmlHelper et al
      self.class.class_eval "include ::Erubis"

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
    rescue LoadError
      raise Webgen::LoadError.new('erubis', self.class.name, context.dest_node, 'erubis')
    rescue Exception => e
      raise Webgen::RenderError.new(e, self.class.name, context.dest_node,
                                    Webgen::Common.error_file(e), Webgen::Common.error_line(e))
    end

  end

end
