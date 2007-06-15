module Tag

  # TODO Base class for all tag plugins. The base class provides a default mechanism for retrieving
  # configuration data from either the configuration file or the tag itself.
  # Tag plugins have to reside in the Tag/ namespace.
  #
  # *Can* be used, but one can also not derive a tag plugin for it
  # Objects must respond to set_tag_config, reset_tag_config, process_tag, tags
  #
  # Addition to params: mandatory: true/default
  # Set the parameter +param+ as mandatory. The parameter +default+ specifies, if this parameter
  # should be the default mandatory parameter. If only a String is supplied in a tag, its value
  # will be assigned to the default mandatory parameter. There *should* be only one default
  # mandatory parameter.
  class DefaultTag

    def initialize
      @cur_config = {}
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

    # Sets the configuration parameters for the next #process_tag call.
    def set_tag_config( config, node )
      @cur_config = {}
      case config
      when Hash
        set_cur_config( config, node )

      when String
        set_default_mandatory_param( config, node )

      when NilClass

      else
        log(:error) { "Invalid parameter type (#{config.class}) for tag '#{plugin_name}' in <#{node.node_info[:src]}>" }
      end

      unless all_mandatory_params_set?
        log(:error) { "Not all mandatory parameters for tag '#{plugin_name}' in <#{node.node_info[:src]}> set" }
      end
    end

    # Resets the call specific tag configuration data.
    def reset_tag_config
      @cur_config = {}
    end

    # Retrieves the parameter value for +name+. The value is taken from the current tag configuration
    # if the parameter is specified there.
    def param( name, plugin = nil )
      if @cur_config.has_key?( name ) && plugin.nil?
        return @cur_config[name]
      else
        super( name, plugin )
      end
    end

    # TODO Default implementation for processing a tag. The parameter +tag+ specifies the name of the tag
    # which should be processed (useful for tag plugins which process different tags).
    #
    # The +node_chain+ parameter holds all relevant nodes. The first node in the chain is always the
    # node in which the tag was found (a template )and the last node is the current node, i.e. the
    # page node which triggered all this. The nodes between are other template nodes.
    #
    # The method has to return the result of the tag processing and, optionally, a modified chain
    # (as second result). The second value is currently only returned by the block tag.
    #
    # Has to be overridden by subclasses!!!
    def process_tag( tag, body, ref_node, node )
      raise NotImplementedError
    end

    #######
    private
    #######

    # Set the current configuration taking values from +config+ which has to be a Hash.
    def set_cur_config( config, node )
      config.each do |key, value|
        if @plugin_manager.plugin_infos[plugin_name]['params'].has_key?( key )
          @cur_config[key] = value
          log(:debug) { "Setting parameter '#{key}' to '#{value}' for tag '#{plugin_name}' in <#{node.node_info[:src]}>" }
        else
          log(:warn) { "Invalid parameter '#{key}' for tag '#{plugin_name}' in <#{node.node_info[:src]}>" }
        end
      end
    end

    # Set the default mandatory parameter.
    def set_default_mandatory_param( value, node )
      param_name, param_value = @plugin_manager.plugin_infos[plugin_name]['params'].find {|k,v| v['mandatory'] == 'default'}
      if param_name.nil?
        log(:error) { "No default mandatory parameter specified for tag '#{plugin_name}' but set in <#{node.node_info[:src]}>"}
      else
        @cur_config[param_name] = value
      end
    end

    # Check if all mandatory parameters have been set
    def all_mandatory_params_set?
      params = @plugin_manager.plugin_infos[plugin_name]['params']
      params.all? {|k,v| !v['mandatory'] || @cur_config.has_key?( k ) }
    end

  end

end
