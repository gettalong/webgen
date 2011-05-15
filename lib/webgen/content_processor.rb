# -*- encoding: utf-8 -*-

require 'webgen/coreext'
require 'webgen/common'
require 'webgen/error'

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
  #   website.ext.content_processor.register '::Replacer'
  #
  class ContentProcessor

    include Webgen::Common::ExtensionManager

    # Register a content processor. The parameter +klass+ has to contain the name of the class which
    # has to respond to +call+ or which has an instance method +call+. If the class is located under
    # this namespace, only the class name without the hierarchy part is needed, otherwise the full
    # class name including parent module/class names is needed. All other parameters can be set
    # through the options hash if the default values aren't sufficient.
    #
    # Instead of registering a class, you can also provide a block that has to take one parameter
    # (the context object).
    #
    # === Options:
    #
    # [:name] The name for the content processor. If not set, it defaults to the snake-case version
    #         of the class name (without the hierarchy part). It should only contain letters.
    #
    # [:type] Defines which type of content the content processor can process. Can be set to either
    #         <tt>:text</tt> (the default) or <tt>:binary</tt>.
    #
    # === Examples:
    #
    #   content_processor.register('Kramdown')     # registers Webgen::ContentProcessor::Kramdown
    #
    #   content_processor.register('::Kramdown')   # registers Kramdown !!!
    #
    #   content_processor.register('MyModule::Doit', type: :binary)
    #
    #   content_processor.register('doit') do |context|
    #     context.content = 'Nothing left.'
    #   end
    #
    def register(klass, options={}, &block)
      options[:type] ||= :text
      do_register(klass, options, [:type], &block)
    end

    # Call the content processor object identified by the given name with the given context.
    def call(name, context)
      extension(name).call(context)
    rescue Webgen::Error
      raise
    rescue Exception => e
      ext = extension(name)
      raise Webgen::RenderError.new(e, (ext.respond_to?(:name) ? ext.name : nil), context.dest_node)
    end

    # Return whether the content processor is processing binary data.
    def is_binary?(name)
      registered?(name) && @extensions[name.to_sym].last == :binary
    end

  end

end
