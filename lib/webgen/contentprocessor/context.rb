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

    def ref_node
      @options[:chain] && @options[:chain].first
    end

    def content_node
      @options[:chain] && @options[:chain].last
    end

  end

end
