require 'webgen/contentprocessor'

module Webgen::ContentProcessor

  # The context object that is passed to the +call+ method of a content processor.
  class Context

    # Processing options
    attr_accessor :options

    def initialize(options = {})
      @options = {
        :content => '',
        :processors => Webgen::ContentProcessor::AccessHash.new
      }.merge(options)
    end

    def clone(attr = {})
      self.class.new(@options.merge(attr))
    end

    def [](name)
      @options[name]
    end

    def []=(name, value)
      @options[name] = value
    end

    def content
      @options[:content]
    end

    def content=(value)
      @options[:content] = value
    end

    # Returns the node which represents the file into which everything gets rendered. This is
    # normally the same node as <tt>#content_node</tt> but can differ in special cases. For example,
    # when rendering the content of node called +my.page+ into the output of the node +this.page+,
    # +this.page+ would be the +dest_node+ and +my.page+ would be the +content_node+.
    #
    # The +dest_node+ is not included in the chain!
    #
    # This node should be used as source node for calculating relative paths to other nodes.
    def dest_node
      @options[:dest_node] || self.content_node
    end

    # Returns the reference node, ie. the node which provided the original content for this context
    # object.
    #
    # This node should be used, for example, for resolving relative paths.
    def ref_node
      @options[:chain] && @options[:chain].first
    end

    # Returns the node that is ultimately rendered. This node should be used, for example, for
    # retrieving meta information.
    def content_node
      @options[:chain] && @options[:chain].last
    end

  end

end
