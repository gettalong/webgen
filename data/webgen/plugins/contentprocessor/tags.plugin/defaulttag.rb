module Tag

  # This class serves as base class for all tag plugins. Have a look a the example below to see
  # how a basic tag plugin looks like.
  #
  # = Tag plugins
  #
  # A tag plugin is a plugin that handles specific webgen tags. webgen tags are used to add dynamic
  # content to page and template files and are easy to use.
  #
  # A tag plugin can handle multiple different tags. The tags which are handled by a tag plugin can
  # either specified in the <tt>plugin.yaml</tt> file using the key +tags+ (either one tag name or
  # an array of tag names) or can be added by calling +register_tag+ in the plugin initialization
  # method. The special name <tt>:default</tt> is used for the default tag plugin which is called if
  # a tag with an unknown tag name is encountered.
  #
  # Derived plugins have to overwrite the method +process_tag+ which is called by
  # ContentProcessor/Tags to the actual processing.
  #
  # Tag plugins *can* use this base class. If they don't derive from this class they have to provide
  # the following methods: +set_params+, +tag_params+, +process_tag+, +tags+.
  #
  # Each tag plugin has to reside under the <tt>Tag/</tt> namespace!
  #
  # = Tag parameters
  #
  # Parameters for tag plugins can be set in the same way as for other plugins. Additionally, webgen
  # tags allow the specification of the parameters in the tag definition. To support this an
  # additional parameter attribute is used: +mandatory+. If this key is set to +true+ for a
  # parameter, the parameter counts as mandatory and needs to be set in the tag definition. If this
  # key is set to +default+, this means that this parameter should be the default mandatory
  # parameter (used when only a string is provided in the tag definition). There *should*
  # be only one default mandatory parameter.
  #
  # = Sample Tag Plugin
  #
  # Following is a simple tag plugin example which just reverses the body text and adds some
  # information about the context to the result:
  #
  # The <tt>plugin.yaml</tt> file:
  #
  #   Tag/Reverser:
  #     plugin:
  #       load_deps: Tag/DefaultTag
  #     params:
  #       do_reverse:
  #         default: ~
  #         desc: Specifies if the body should actually be reversed.
  #         mandatory: default
  #     tags: reverse
  #
  # The <tt>plugin.rb</tt> file:
  #
  #   module Tag
  #
  #   class Reverser < DefaultTag
  #
  #     def process_tag( tag, body, context )
  #       result = param('do_reverse') ? body.reverse: body
  #       result += "Node: " + context.node.absolute_lcn + " (" + context.node['title'] + ")"
  #       result += "Reference node: " + context.ref_node.absolute_lcn
  #       result
  #     end
  #
  #   end
  #
  #   end
  #
  class DefaultTag

    def initialize
      @tags = []
    end

    # Adds the tag +tag+ to the list of the tags that get processed by the plugin.
    def register_tag( tag )
      @tags << tag
    end
    protected :register_tag

    # Returns all registered tags for the plugin.
    def tags
      [@plugin_manager.plugin_infos.get( @plugin_name, 'tags' ), @tags].flatten.compact
    end

    # Returns a parameters hash with param values extracted from the +tag_config+.
    def tag_params( tag_config, ref_node )
      begin
        config = YAML::load( "--- #{tag_config}" )
      rescue ArgumentError => e
        log(:error) { "Could not parse the tag params '#{tag_config}' in <#{ref_node.nod_info[:src]}>: #{e.message}" }
        config = {}
      end
      create_params_hash( config, ref_node )
    end

    # Sets the current parameter configuration to +params+.
    def set_params( params )
      @params = params
    end

    # Retrieves the parameter value for +name+. The value is taken from the current tag configuration
    # if the parameter is specified there.
    def param( name, plugin = nil )
      (@params && @params.has_key?(name) && plugin.nil? ? @params[name] : super)
    end

    # Default implementation for processing a tag. The parameter +tag+ specifies the name of the tag
    # which should be processed (useful for tag plugins which process different tags).
    #
    # The parameter +body+ holds the optional body value for the tag.
    #
    # The context parameter holds all relevant information for processing. Have a look at the
    # Context class information to see what is available.
    #
    # The method has to return the result of the tag processing and, optionally, a boolean value
    # specifying if the result should further be processed (ie. webgen tags replaced).
    #
    # Has to be overridden by subclasses!!!
    def process_tag( tag, body, context )
      raise NotImplementedError
    end

    #######
    private
    #######

    def create_params_hash( config, node )
      params = @plugin_manager.plugin_infos[plugin_name]['params']
      result = case config
               when Hash then create_from_hash( config, params, node )
               when String then create_from_string( config, params, node )
               when NilClass then {}
               else
                 log(:error) { "Invalid parameter type (#{config.class}) for tag '#{plugin_name}' in <#{node.absolute_lcn}>" }
                 {}
               end

      unless params.all? {|k,v| !v['mandatory'] || result.has_key?( k )}
        log(:error) { "Not all mandatory parameters for tag '#{plugin_name}' in <#{node.absolute_lcn}> set" }
      end

      result
    end

    # Returns a valid parameter hash taking values from +config+ which has to be a Hash.
    def create_from_hash( config, params, node )
      result = {}
      config.each do |key, value|
        if params.has_key?( key )
          result[key] = value
          log(:debug) { "Setting parameter '#{key}' to '#{value}' for tag '#{plugin_name}' in <#{node.absolute_lcn}>" }
        else
          log(:warn) { "Invalid parameter '#{key}' for tag '#{plugin_name}' in <#{node.absolute_lcn}>" }
        end
      end
      result
    end

    # Returns a valid parameter hash by setting +value+ to the default mandatory parameter.
    def create_from_string( value, params, node )
      param_name, param_value = params.find {|k,v| v['mandatory'] == 'default'}
      if param_name.nil?
        log(:error) { "No default mandatory parameter specified for tag '#{plugin_name}' but set in <#{node.absolute_lcn}>"}
        {}
      else
        {param_name => value}
      end
    end

  end

end
