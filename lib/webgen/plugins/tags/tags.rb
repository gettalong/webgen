#
#--
#
# $Id$
#
# webgen: template based static website generator
# Copyright (C) 2004 Thomas Leitner
#
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU
# General Public License as published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program; if not,
# write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#++
#

require 'yaml'

module Tags

  #TODO new comment: This is the main class for tags. Tag plugins can register themselves by adding a new key:value
  # pair to +tags+. The key has to be the name of the tag as specified in the page description files
  # and the value is the plugin object itself. When the content is parsed and a tag is
  # encountered, the registered plugin for the tag is called. If no plugin for a tag is registered
  # but a default plugin is, the default plugin is called. Otherwise an error is raised.
  #
  # The default plugin can be registered by using the special key <tt>:default</tt>.
  class TagProcessor < Webgen::Plugin

    infos :summary => "Plugin for processing tags"

    #TODO new comment: Substitutes all references to tags in the string +content+. The +node+ parameter specifies the
    # tree node the content of which is used. The +refNode+ parameter specifies relative to which
    # all references should be resolved.
    def process( content, chain )
      if !content.kind_of?( String )
        log(:error) { "The content in <#{chain.first.node_info[:src]}> is not a string, but a #{content.class.name}" }
        content = content.to_s
      end

      return replace_tags( content, chain.first ) do |tag, tag_data|
        log(:info) { "Replacing tag #{tag} with data '#{tag_data}' in <#{chain.first.full_path}>" }

        processor = processor_for_tag( tag )
        begin
          processor.set_tag_config( YAML::load( "--- #{tag_data}" ), chain.first )
        rescue ArgumentError => e
          self.logger.error { "Could not parse the data '#{tag_data}' for tag #{tag} in <#{node.nod_info[:src]}>: #{e.message}" }
        end
        result, tag_chain = processor.process_tag( tag, chain )
        processor.reset_tag_config

        result = process( result, tag_chain ) if processor.process_output? && !tag_chain.nil?
        result
      end
    end

    #######
    private
    #######

    # Scans the +content+ for tags. If a tag is found, the block is called which needs to return the
    # value for the given tag. The changed content is returned.
    def replace_tags( content, node ) # :yields: tag, data
      offset = 0;
      content = content.dup
      while index = content.index( /(\\*)\{(\w+):/, offset )
        bracketCount = 1;
        length = $1.length + 1;
        tag = $2
        content[(index + length)..-1].each_byte do |char|
          length += 1
          bracketCount += 1 if char == ?{
          bracketCount -= 1 if char == ?}
          break if bracketCount == 0
        end

        if bracketCount > 0
          log(:error) { "Unbalanced curly brackets in <#{node.node_info[:src]}>!!!" }
          newContent = content[index, length]
        else
          newContent = "\\"* ( $1.length / 2 )
          if $1.length % 2 == 1
            newContent += content[index + $1.length, length - $1.length]
          else
            tagHeaderLength = $1.length + tag.length + 2
            realContent = content[index + tagHeaderLength, length - tagHeaderLength - 1].lstrip
            newContent += yield( tag, realContent ).to_s
          end
          content[index, length] = newContent
        end
        offset = index + newContent.length
      end
      content
    end


    # Returns the tag processor for +tag+ or +nil+ if +tag+ is unknown.
    def processor_for_tag( tag )
      tags = registered_tags
      if tags.has_key?( tag )
        tags[tag]
      elsif tags.has_key?( :default )
        tags[:default]
      else
        log(:error) { "No tag processor for tag '#{tag}' found" }
      end
    end

    # Returns a hash of the registered tag plugins with the tag name as key.
    def registered_tags
      tags = {}
      @plugin_manager.plugins.each do |name, plugin|
        if plugin.kind_of?( DefaultTag )
          #TOOD write log message if duplicate tag name
          plugin.tags.each {|tag| tags[tag] = plugin }
        end
      end
      tags
    end

  end


  # Base class for all tag plugins. The base class provides a default mechanism for retrieving
  # configuration data from either the configuration file or the tag itself.
  class DefaultTag < Webgen::Plugin

    infos(
          :summary => "Base class for all tag plugins",
          :instantiate => false
          )

    def initialize( plugin_manager )
      super
      @process_output = true
      @cur_config = {}
      @tags = []
    end

    # Returns +true+ if the output should be processed again
    def process_output?
      @process_output
    end

    # Set the parameter +param+ as mandatory. The parameter +default+ specifies, if this parameter
    # should be the default mandatory parameter. If only a String is supplied in a tag, its value
    # will be assigned to the default mandatory parameter. There *should* be only one default
    # mandatory parameter.
    def self.set_mandatory( param, default = false )
      if self.config.params.nil? || !self.config.params.has_key?( param )
        $stderr.puts( "Cannot set parameter #{param} as mandatory as this parameter does not exist for #{self.name}" ) if $VERBOSE
      else
        self.config.params[param].mandatory = true
        self.config.params[param].mandatory_default = default
      end
    end

    # Register +tag+ so that it gets processed by the current class.
    def self.register_tag( tag )
      (self.config.infos[:tags] ||= [] ) << tag
    end

    # See DefaultTag.tag
    def register_tag( tag )
      @tags << tag
    end

    # Returns all registered tags for the plugin.
    def tags
      (self.class.config.infos[:tags] || []) + @tags
    end

    # Set the configuration parameters for the next #process_tag call. The configuration, if
    # specified, is taken from the tag itself.
    def set_tag_config( config, node )
      @cur_config = {}
      case config
      when Hash
        set_cur_config( config, node )

      when String
        set_default_mandatory_param( config, node )

      when NilClass
        if has_mandatory_params?
          log(:error) { "Mandatory parameters for tag '#{self.class.name}' in <#{node.node_info[:src]}> not specified" }
        end

      else
        log(:error) { "Invalid parameter for tag '#{self.class.name}' in <#{node.node_info[:src]}>" }
      end

      unless all_mandatory_params_set?
        log(:error) { "Not all mandatory parameters for tag '#{self.class.name}' in <#{node.node_info[:src]}> set" }
      end
    end


    # Resets the tag configuration data.
    def reset_tag_config
      @cur_config = {}
    end

    # Retrieves the parameter value for +name+. The value is taken from the current tag if the
    # parameter is specified there or the default value set in #register_config_value is used.
    def param( name, plugin = nil )
      if @cur_config.has_key?( name ) && plugin.nil?
        return @cur_config[name]
      else
        super( name, plugin )
      end
    end

    # Default implementation for processing a tag.
    #
    # Has to be overridden by subclasses!!!
    def process_tag( tag, node_chain )
      raise NotImplementedError
    end

    #######
    private
    #######

    # Set the current configuration taking values from +config+ which has to be a Hash.
    def set_cur_config( config, node )
      config.each do |key, value|
        if self.class.config.params.has_key?( key )
          @cur_config[key] = value
          log(:debug) { "Setting parameter '#{key}' for tag '#{self.class.name}' in <#{node.node_info[:src]}>" }
        else
          log(:warn) { "Invalid parameter '#{key}' for tag '#{self.class.name}' in <#{node.node_info[:src]}>" }
        end
      end
    end

    # Set the default mandatory parameter.
    def set_default_mandatory_param( value, node )
      param_name, param_value = self.class.config.params.find {|k,v| v.mandatory_default} unless self.class.config.params.nil?
      if param_name.nil?
        log(:error) { "No default mandatory parameter specified for tag '#{self.class.name}' but set in <#{node.node_info[:src]}>"}
      else
        @cur_config[param_name] = value
      end
    end

    # Check if this tag has mandatory parameters.
    def has_mandatory_params?
      !self.class.config.params.nil? && self.class.config.params.any? {|k,v| v.mandatory }
    end

    # Check if all mandatory parameters have been set
    def all_mandatory_params_set?
      params = self.class.config.params
      ( params.nil? ? true : params.all? { |k,v| !v.mandatory || @cur_config.has_key?( k ) } )
    end

  end

end
