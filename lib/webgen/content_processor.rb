# -*- encoding: utf-8 -*-

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
  # Or as a Proc object.
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
  #     def self.call(context)
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
  #   website.ext.content_processor.register Replacer, :name => 'replacer'
  #
  class ContentProcessor

    include Webgen::Common::ExtensionManager

    # Register a content processor. The parameter +klass+ has to contain the name of the class which
    # has to respond to +call+ or which has an instance method +call+. If the class is located under
    # this namespace, only the class name without the hierarchy part is needed, otherwise the full
    # class name including parent module/class names is needed.
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
    # [:author] The author of the content processor.
    #
    # [:summary] A short description of the content processor.
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
      name = do_register(klass, options, true, &block)
      ext_data(name).type = options[:type] || :text
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

    # Normalize the content processor pipeline.
    #
    # The pipeline parameter can be a String in the format 'a,b,c' or 'a, b, c' or an array '[a, b,
    # c]' with content processors a, b and c.
    #
    # Raises an error if an unknown content processor is found.
    #
    # Returns an array with valid content processors.
    def normalize_pipeline(pipeline)
      pipeline = (pipeline.kind_of?(String) ? pipeline.split(/,\s*/) : pipeline)
      pipeline.each do |processor|
        raise Webgen::Error.new("Unknown content processor '#{processor}'") if !registered?(processor)
      end
      pipeline
    end

    # Return whether the content processor is processing binary data.
    def is_binary?(name)
      registered?(name) && ext_data(name).type == :binary
    end

  end

end
