# -*- encoding: utf-8 -*-

require 'webgen/common'

module Webgen

  # Namespace for all content processors.
  #
  # == Implementing a content processor
  #
  # Content processors are used to process the content of files, normally of files in Webgen Page
  # Format. However, they can potentially process any type of content, even binary content.
  #
  # There are basically three ways to implement a content processor.
  #
  # A content processor only needs to respond to one method called +call+. This method is invoked
  # with a Webgen::Context object that provides the whole context (especially the content and the
  # node chain) and the method needs to return this object. During processing a content processor
  # normally changes the content of the context but it does not need to.
  #
  # This allows one to implement a content processor as a class with a class method called +call+.
  # Or as a class with an instance method +call+ because then webgen automatically extends the class
  # so that it has a suitable class method +call+ (note that the +initialize+ method must not take
  # any parameters). Or as a Proc object.
  #
  # The content processor has to be registered so that webgen knows about it, see ::register for
  # more information.
  #
  #
  # == Sample Content Processor
  #
  # The following sample content processor checks for a meta information +replace_key+ and replaces
  # strings of the form <tt>replace_key:path/to/node</tt> with a link to the specified node if it is
  # found.
  #
  # Note how the content node, the reference node and the destination node are used so that the
  # correct meta information is used, the node is correctly resolved and the correct relative link
  # is calculated respectively!
  #
  #   class Replacer
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
  #   Webgen::ContentProcessor.register 'Replacer'
  #
  module ContentProcessor

    module Callable # :nodoc:

      def call(context)
        new.call(context)
      end

    end

    @@processors = {}

    # Register a content processor. The parameter +klass+ has to contain the name of the class which
    # has to respond to +call+ or which has an instance method +call+. If the class is located under
    # this module, only the class name without the hierarchy part is needed, otherwise the full
    # class name including parent module/class names is needed. All other parameters can be set
    # through the options hash if the default values aren't sufficient.
    #
    # Instead of registering a class, you can also provide a block that has to take one parameter
    # (the context object).
    #
    # === Options:
    #
    # [:short_name] The short name for the content processor. If not set, it defaults to the
    #               lowercase version of the class name (without the hierarchy part). It should only
    #               contain letters.
    #
    # [:type] Defines which type of content the content processor can process. Can be set to either
    #         <tt>:text</tt> (the default) or <tt>:binary</tt>.
    #
    # === Examples:
    #
    #   Webgen::ContentProcessor.register(:Kramdown)
    #
    #   Webgen::ContentProcessor.register('MyModule::Doit', type: :binary)
    #
    #   Webgen::ContentProcessor.register('doit') do |context|
    #     context.content = 'Nothing left.'
    #   end
    #
    def self.register(klass, options={}, &block)
      short_name = options[:short_name] || klass.to_s.downcase
      type = options[:type] || :text
      @@processors[short_name.to_sym] = [block_given? ? block : klass.to_s, type]
      autoload(klass.to_sym, "webgen/content_processor/#{short_name}") unless block_given? || klass.to_s.include?('::')
    end

    # Return +true+ if there is a content processor with the given short name.
    def self.registered?(short_name)
      @@processors.has_key?(short_name.to_sym)
    end

    # Return the short names of all available content processors.
    def self.short_names
      @@processors.keys {|k| k.to_s}.sort
    end

    # Call the content processor object identified by the given short name with the given context.
    def self.call(short_name, context)
      return nil unless registered?(short_name)
      class_or_name = @@processors[short_name.to_sym].first
      if String === class_or_name
        class_or_name =  if !class_or_name.include?('::') && const_defined?(class_or_name.to_sym)
                           const_get(class_or_name)
                         else
                           Webgen::Common.const_for_name(class_or_name)
                         end
        class_or_name.extend(Callable)
        @@processors[short_name.to_sym][0] = class_or_name
      end
      class_or_name.call(context)
    end

    # Return whether the content processor is processing binary data.
    def self.is_binary?(short_name)
      registered?(short_name) && @@processors[short_name.to_sym].last == :binary
    end

    register :Tags
    register :Blocks
    register :Maruku
    register :RedCloth
    register :Erb
    register :Haml
    register :Sass
    register :Scss
    register :RDoc
    register :Builder
    register :Erubis
    register :RDiscount
    register :Fragments
    register :Head
    register :Tidy
    register :Xmllint
    register :Kramdown
    register :Less

  end

end
