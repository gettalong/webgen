# -*- encoding: utf-8 -*-

require 'webgen/error'

module Webgen
  class Context

    # Provides methods for adding data for Webgen::ContentProcessor::HtmlHead.
    module HtmlHead

      # Proxy object for working with the data structure needed by
      # Webgen::ContentProcessor::HtmlHead.
      class Proxy

        def initialize(context) #:nodoc:
          @context = context
        end

        # Add a link to the given file in the HTML head section.
        #
        # The type can either be :css for CSS files or :js for javascript files. The path to the
        # file is resolved using the "relocatable" tag (see Webgen::Tag::Relocatable).
        def link_file(type, file)
          type_check!(type)
          (cp_hash["#{type}_file".intern] ||= []) << @context.tag('relocatable', file)
        end

        # Add inline CSS or JS fragments to the HTML head section.
        #
        # The type can either be :css for a CSS fragment or :js for a javascript fragment.
        def inline_fragment(type, content)
          type_check!(type)
          (cp_hash["#{type}_inline".intern] ||= []) << content
        end

        def type_check!(type) #:nodoc:
          if ![:css, :js].include?(type)
            raise Webgen::RenderError.new("Type must either be :css or :js, not #{type}",
                                          self.class.name, @context.dest_node, @context.ref_node)
          end
        end
        private :type_check!

        def cp_hash #:nodoc:
          @context.persistent[:cp_html_head] ||= {}
        end
        private :cp_hash

      end

      # Return the Proxy object for adding data to the context for
      # Webgen::ContentProcessor::HtmlHead.
      def html_head
        Proxy.new(self)
      end

    end

  end
end
