require 'webgen/contentprocessor'

module Webgen::ContentProcessor

  # The context object that is passed to the +call+ method of a content processor.
  #
  # The needed context variables are stored in the +options+ hash. You can set any options you like,
  # however, there are three noteworthy options:
  #
  # <tt>:content</tt>:: The content string that should be processed.
  # <tt>:processors</tt>:: Normally an AccessHash object providing access to all available content processors.
  # <tt>:chain</tt>:: The chain of nodes that is processed. There are some utiltity methods for getting
  #                   special nodes of the chain (see #ref_node, #content_node).
  class Context

    # Processing options
    attr_accessor :options

    # Create a new Context object. You can use the +options+ hash to set needed options. The
    # <tt>:content</tt> option is set to an empty string if not specified in +options+ and
    # <tt>:processors</tt> is set to a new AccessHash if not specified in +options+.
    def initialize(options = {})
      @options = {
        :content => '',
        :processors => Webgen::ContentProcessor::AccessHash.new
      }.merge(options)
    end

    # Create a copy of the current object. You can use the +options+ parameter to override options
    # of the current Context object in the newly created Context object.
    def clone(options = {})
      self.class.new(@options.merge(options))
    end

    # Return the value of the option +name+.
    def [](name)
      @options[name]
    end

    # Set the option +name+ to the given +value.
    def []=(name, value)
      @options[name] = value
    end

    # Return the <tt>:content</tt> option.
    def content
      @options[:content]
    end

    # Set the <tt>:content</tt> option to the given +value+.
    def content=(value)
      @options[:content] = value
    end

    # Return the node which represents the file into which everything gets rendered. This is
    # normally the same node as <tt>#content_node</tt> but can differ in special cases. For example,
    # when rendering the content of node called <tt>my.page</tt> into the output of the node
    # <tt>this.page</tt>, <tt>this.page</tt> would be the +dest_node+ and <tt>my.page</tt> would be
    # the +content_node+.
    #
    # The +dest_node+ is not included in the chain but can be set via the option
    # <tt>:dest_node</tt>!
    #
    # The returned node should be used as source node for calculating relative paths to other nodes.
    def dest_node
      @options[:dest_node] || self.content_node
    end

    # Return the reference node, ie. the node which provided the original content for this context
    # object.
    #
    # The returned node should be used, for example, for resolving relative paths.
    def ref_node
      @options[:chain] && @options[:chain].first
    end

    # Return the node that is ultimately rendered.
    #
    # This node should be used, for example, for retrieving meta information.
    def content_node
      @options[:chain] && @options[:chain].last
    end

  end

end
