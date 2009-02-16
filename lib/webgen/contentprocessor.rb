# -*- encoding: utf-8 -*-

module Webgen

  # Namespace for all content processors.
  #
  # = Implementing a content processor
  #
  # Content processors are used to process the content of files, normally of files in Webgen Page
  # Format. A content processor only needs to respond to one method called +call+ and must not take
  # any parameters in the +initialize+ method. This method is invoked with a
  # Webgen::ContentProcessor::Context object that provides the whole context (especially the content
  # and the node chain) and the method needs to return this object. During processing a content
  # processor normally changes the content of the context but it does not need to.
  #
  # A self-written content processor does not need to be in the Webgen::ContentProcessor namespace
  # but all shipped ones do.
  #
  # After writing the content processor class, one needs to add it to the
  # <tt>contentprocessor.map</tt> hash so that it is used by webgen. The key for the entry needs to
  # be a short name without special characters or spaces and the value is the class name, not as
  # constant but as a string.
  #
  # = Sample Content Processor
  #
  # The following sample content processor checks for a meta information +replace_key+ and replaces
  # strings of the form <tt>replace_key:path/to/node</tt> with a link to the specified node if it is
  # found.
  #
  # Note how the content node, the reference node and the destination node are used sothat the
  # correct meta information is used, the node is correctly resolved and the correct relative link
  # is calculated respectively!
  #
  #   class SampleProcessor
  #
  #     def call(context)
  #       if !context.content_node['replace_key'].to_s.empty?
  #         context.content.gsub!(/#{context.content_node['replace_key']}:([\w\/.]+)/ ) do |match|
  #           link_node = context.ref_node.resolve($1, context.content_node.lang)
  #           if link_node
  #             context.dest_node.link_to(link_node, :lang => context.content_node.lang)
  #           else
  #             match
  #           end
  #         end
  #       end
  #       context
  #     rescue Exception => e
  #       raise "Error while replacing special key: #{e.message}"
  #     end
  #
  #   end
  #
  #   WebsiteAccess.website.config['contentprocessor.map']['replacer'] = 'SampleProcessor'
  #
  module ContentProcessor

    autoload :Context, 'webgen/contentprocessor/context'
    autoload :Tags, 'webgen/contentprocessor/tags'
    autoload :Blocks, 'webgen/contentprocessor/blocks'
    autoload :Maruku, 'webgen/contentprocessor/maruku'
    autoload :RedCloth, 'webgen/contentprocessor/redcloth'
    autoload :Erb, 'webgen/contentprocessor/erb'
    autoload :Haml, 'webgen/contentprocessor/haml'
    autoload :Sass, 'webgen/contentprocessor/sass'
    autoload :RDoc, 'webgen/contentprocessor/rdoc'
    autoload :Builder, 'webgen/contentprocessor/builder'
    autoload :Erubis, 'webgen/contentprocessor/erubis'
    autoload :RDiscount, 'webgen/contentprocessor/rdiscount'
    autoload :Fragments, 'webgen/contentprocessor/fragments'

    # Return the list of all available content processors.
    def self.list
      WebsiteAccess.website.config['contentprocessor.map'].keys
    end

    # Return the content processor object identified by +name+.
    def self.for_name(name)
      klass = WebsiteAccess.website.config['contentprocessor.map'][name]
      klass.nil? ? nil : WebsiteAccess.website.cache.instance(klass)
    end

    # Helper class for accessing content processors in a Webgen::ContentProcessor::Context object.
    class AccessHash

      # Check if a content processor called +name+ exists.
      def has_key?(name)
        Webgen::ContentProcessor.list.include?(name)
      end

      # Return (and proboably initialize) the content processor called +name+.
      def [](name)
        Webgen::ContentProcessor.for_name(name)
      end
    end

  end

end
