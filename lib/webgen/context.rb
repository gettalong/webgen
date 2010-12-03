# -*- encoding: utf-8 -*-

module Webgen

  # This class represents the context object that is passed, for example, to the +call+ method of a
  # content processor.
  #
  # == About
  #
  # A context object provides information about the render context as well as access to the website
  # that is rendered. The needed context variables are stored in the +options+ hash. You can set any
  # options you like, however, there are two noteworthy options:
  #
  # [<tt>:content</tt>]
  #   The content string that should be processed. This option is always set.
  #
  # [<tt>:chain</tt>]
  #   The chain of nodes that is processed. There are some utiltity methods for getting
  #   special nodes of the chain (see Nodes#ref_node, Nodes#content_node and Nodes#dest_node).
  #
  # The +persistent+ options hash is shared by all cloned Context objects.
  #
  # == Adding custom methods
  #
  # If you want to add custom methods to each context object of your website that is created, you
  # just need to define one or more modules in which your custom methods are defined and then add
  # the modules to the <tt>website.ext.context_modules</tt> array (or create it if it does not
  # exist).
  #
  # Here is a simple (nonsensical) example:
  #
  #   module MyContextMethods
  #
  #     def my_method
  #       # do something useful here
  #     end
  #
  #   end
  #
  #   (website.ext.context_modules ||= []) << MyContextMethods
  #
  class Context

    require 'webgen/context/nodes'
    require 'webgen/context/webgen_tags'
    require 'webgen/context/rendering'

    include Nodes
    include WebgenTags
    include Rendering


    # The persistent options. Once initialized, all cloned objects refer to the same hash.
    attr_reader :persistent

    # Processing options.
    attr_reader :options

    # The website object to which the render context belongs.
    attr_reader :website

    # Create a new Context object belonging to the website object +website+. All modules listed in
    # the array <tt>website.ext.context_modules</tt> are automatically used to extend the Context
    # object.
    #
    # The following options are set by default and can be overridden via the +options+ hash:
    #
    # [<tt>:content</tt>]
    #   Is set to an empty string.
    def initialize(website, options = {}, persistent = {})
      @website = website
      (website.ext.context_modules || []).each {|m| self.extend(m)}
      @options = {:content => ''}.merge(options)
      @persistent = persistent
    end

    # Create a copy of the current object. You can use the +options+ parameter to override options
    # of the current Context object in the newly created Context object.
    def clone(options = {})
      self.class.new(@website, @options.merge(options), @persistent)
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
