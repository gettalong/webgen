# -*- encoding: utf-8 -*-
require 'webgen/context/nodes'

module Webgen

  # This class represents the context object that is passed, for example, to the +call+ method of a
  # content processor.
  #
  # The needed context variables are stored in the +options+ hash. You can set any options you like,
  # however, there are three noteworthy options:
  #
  # [<tt>:content</tt>]
  #   The content string that should be processed.
  #
  # [<tt>:processors</tt>]
  #   Normally an AccessHash object providing access to all available content processors.
  #
  # [<tt>:chain</tt>]
  #   The chain of nodes that is processed. There are some utiltity methods for getting
  #   special nodes of the chain (see #ref_node, #content_node and #dest_node).
  class Context

    include Webgen::WebsiteAccess
    public :website

    # Processing options
    attr_accessor :options

    # Create a new Context object. You can use the +options+ hash to set needed options.
    #
    # The following options are set by default and can be overridden via the +options+ hash:
    #
    # [<tt>:content</tt>]
    #   Is set to an empty string.
    #
    # [<tt>:processors</tt>]
    #   Is set to a new AccessHash.
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

  end

end
