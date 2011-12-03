# -*- encoding: utf-8 -*-

require 'webgen/common'
require 'webgen/error'
require 'webgen/utils/tag_parser'

module Webgen

  # Namespace for all webgen tags. A tag object is a webgen extension that handles specific webgen
  # tags. webgen tags are used to add dynamic content to page and template files and are made for
  # ease of use.
  #
  # == Implementing a tag
  #
  # A tag object only needs to respond to the method +call+ which needs to accept three parameters:
  #
  # [tag]: The name of the tag which should be processed (useful for tag objects which can process
  #        different tags).
  #
  # [body]: Holds the body value for the tag if any.
  #
  # [context]: Holds all relevant information for processing -- have a look at the Webgen::Context
  #            class to see what is available. The special key <tt>:config</tt> is set to an
  #            Webgen::Configuration object that should be used to retrieve configuration option
  #            values because the values might be changed due to options set directly via the tag
  #            syntax.
  #
  # The method has to return the result of the processing and, optionally, a boolean value
  # specifying if the result should further be processed (ie. webgen tags replaced).
  #
  # This allows one to implement a tag object as a class with a class method called +call+. Or as a
  # Proc object.
  #
  # The tag object has to be registered so that webgen knows about it, see ::register for more
  # information.
  #
  # == Tag options
  #
  # webgen tags allow the specification of options in the tag definition. When registering a tag,
  # one can specify which options are mandatory, i.e. which options always have to be set directly
  # for the tag. The value of the option <tt>:config_base</tt> for the ::register method is used to
  # resolve partially stated configuration entries.
  #
  # == Sample Tag
  #
  # Following is a simple tag class example which just reverses the body text and adds some
  # information about the context to the result.
  #
  #   class Reverser
  #
  #     def self.call(tag, body, context)
  #       result = context[:config]['do_reverse'] ? body.reverse : body
  #       result << "Node: " << context.content_node.alcn << " (" << context.content_node['title'] << ")"
  #       result << "Reference node: " << context.ref_node.alcn
  #       result
  #     end
  #
  #   end
  #
  #   website.config.define_option('reverser.do_reverse', nil, 'Actually reverse')
  #   website.ext.tag.register '::Reverser', :names => 'reverse', :mandatory => ['reverse']
  #
  class Tag

    include Webgen::Common::ExtensionManager

    TagData = Struct.new(:callable, :config_base, :mandatory_options, :initialized)

    def initialize(website) # :nodoc:
      super()
      website.blackboard.add_listener(:configuration_loaded, self) do
        @parser = Webgen::Utils::TagParser.new(website.config['tag.prefix'])
      end
    end

    # Register a tag. The parameter +klass+ has to contain the name of the class which has to
    # respond to +call+ or which has an instance method +call+. If the class is located under this
    # namespace, only the class name without the hierarchy part is needed, otherwise the full class
    # name including parent module/class names is needed.
    #
    # Instead of registering a class, you can also provide a block that processes a tag.
    #
    # === Options:
    #
    # [:names] The tag name or an array of tag names. If not set, it defaults to the lowercase
    #          version of the class name (without the hierarchy part). The name <tt>:default</tt> is
    #          used for specifying the default tag which is called if an unknown tag name is
    #          encountered.
    #
    # [:config_base] The configuration base, i.e. the part of a configuration option name that does
    #                not need to be specified. Defaults to the full class name without the Webgen
    #                module downcased and all "::" substituted with "." (e.g. Webgen::Tag::Menu →
    #                tag.menu).
    #
    # [:mandatory] A list of configuration option names whose values always need to be provided. The
    #              first configuration option name is used as the default mandatory option (used
    #              when only a string is provided in the tag definition).
    #
    # === Examples:
    #
    #   tag.register('Date')    # registers Webgen::Tag::Date
    #
    #   tag.register('::Date')  # registers Date !!!
    #
    #   tag.register('MyModule::Date', names: ['mydate', 'date'])
    #
    #   tag.register('date') do |tag, body, context|
    #     Time.now.strftime(param('tag.date.format'))
    #   end
    #
    def register(klass, options={}, &block)
      klass, klass_name = normalize_class_name(klass, !block_given?)
      tag_names = [options[:names] || Webgen::Common.snake_case(klass_name)].flatten.map {|n| n.to_sym}
      config_base = options[:config_base] || klass.gsub(/::/, '.').gsub(/^Webgen\./, '').downcase
      data = TagData.new(block_given? ? block : klass, config_base, options[:mandatory] || [], false)
      tag_names.each {|tname| @extensions[tname] = data}
    end

    # Process the +tag+ and return the result. The parameter +params+ (can be a Hash, a String or
    # nil) needs to contain the parameters for the tag and +body+ is the optional body for the tag.
    # +context+ needs to be a valid Webgen::Context object.
    def call(tag, params, body, context)
      result = ''
      tdata = tag_data(tag, context)
      if !tdata.nil?
        context[:config] = create_config(tag, params, tdata, context)
        result, process_output = tdata.callable.call(tag, body, context)
        result = context.website.ext.content_processor.call('tags', context.clone(:content => result)).content if process_output
      else
        raise Webgen::RenderError.new("No tag processor for '#{tag}' found", self.class.name,
                                      context.dest_node, context.ref_node)
      end
      result
    end

    # See Webgen::Utils::TagParser#replace_tags.
    def replace_tags(str, &block)  #:yields: tag_name, params, body
      @parser.replace_tags(str, &block)
    end

    #######
    private
    #######

    # Create the Webgen::Configuration object from the parameters and the given configuration
    # base.
    def create_config(tag, params, tdata, context)
      values = case params
               when Hash then values_from_hash(tag, params, tdata, context)
               when String then values_from_string(tag, params, tdata, context)
               when NilClass then {}
               else
                 raise Webgen::RenderError.new("Invalid parameter type (#{params.class})",
                                               self.class.name, context.dest_node, context.ref_node)
               end

      if !tdata.mandatory_options.all? {|k| values.has_key?(k)}
        raise Webgen::RenderError.new("Not all mandatory parameters set", self.class.name, context.dest_node, context.ref_node)
      end
      config = context.website.config.dup
      config.set_values(values)
      config.freeze
      config
    end

    # Return a hash containing valid configuration options by taking key-value pairs from +params+.
    def values_from_hash(tag, params, tdata, context)
      result = {}
      params.each do |key, value|
        if context.website.config.option?(key)
          result[key] = value
        elsif context.website.config.option?(tdata.config_base + '.' + key)
          result[tdata.config_base + '.' + key] = value
        else
          context.website.logger.warn do
            "Invalid configuration option '#{key}' for tag '#{tag}' found in <#{context.ref_node}>"
          end
        end
      end
      result
    end

    # Return a hash containing valid configuration options by setting the default mandatory
    # parameter for +tag+ to +str+.
    def values_from_string(tag, str, tdata, context)
      if tdata.mandatory_options.first.nil?
        context.website.logger.error do
          "No default mandatory option specified for tag '#{tag}' but set in <#{context.ref_node}>"
        end
        {}
      else
        {tdata.mandatory_options.first => str}
      end
    end

    # Return the tag data for +tag+ or +nil+ if +tag+ is unknown.
    def tag_data(tag, context)
      tdata = @extensions[tag.to_sym] || @extensions[:default]
      if tdata && !tdata.initialized
        tdata.callable = resolve_class(tdata.callable)
        tdata.mandatory_options.each_with_index do |o, index|
          next if context.website.config.option?(o)
          o = tdata.config_base + '.' + o
          if context.website.config.option?(o)
            tdata.mandatory_options[index] = o
          else
            raise ArgumentError, "Invalid configuration option name '#{o}' specified as mandatory option for tag '#{tag}'"
          end
        end
        tdata.initialized = true
      end
      tdata
    end

  end

end
