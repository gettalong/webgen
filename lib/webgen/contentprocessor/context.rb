module Webgen::ContentProcessor

  # The context object that is passed to the +call+ method of a content processor.
  class Context

    # The to be processed content.
    attr_accessor :content

    # Processing options
    attr_accessor :options

    def initialize(content = '', options = {})
      @content, @options = content, options
    end

    def [](name)
      @options[name]
    end

    def []=(name, value)
      @options[name] = value
    end

  end

end
