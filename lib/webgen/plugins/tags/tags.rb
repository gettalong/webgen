#
#--
#
# $Id$
#
# webgen: a template based web page generator
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
require 'util/ups'

module Tags

  # This is the main class for tags. Tag plugins can register themselves by adding a new key:value
  # pair to +tags+. The key has to be the name of the tag as specified in the page description files
  # and the value is the plugin object itself. When the content is parsed and a tag is
  # encountered, the registered plugin for the tag is called. If no plugin for a tag is registered
  # but a default plugin is, the default plugin is called. Otherwise an error is raised.
  #
  # The default plugin can be registered by using the special key <tt>:default</tt>.
  class Tags < UPS::Plugin

    NAME = "Tags"
    SHORT_DESC = "Super plugin for handling tags"

    Webgen::WebgenError.add_entry :UNKNOWN_TAG,
      "found tag {%0: ...} for which no plugin exists",
      "either remove the tag or implement a plugin for it"

    Webgen::WebgenError.add_entry :CONTENT_NOT_STRING,
      "the content in the file <%1> is not a string: \"$0\"",
      "check the syntax of the file"


    # Tag plugins should add an entry to this hash.
    attr_accessor :tags

    def initialize
      @tags = Hash.new
    end


    # Substitutes all references to tags in the string +content+. The +node+ parameter specifies the
    # tree node the content of which is used. The +refNode+ parameter specifies relative to which
    # all references should be resolved.
    def substitute_tags( content, node, refNode )
      if !content.kind_of? String
        raise Webgen::WebgenError.new( :CONTENT_NOT_STRING, content, refNode['src'] )
      end
      content.gsub!(/(\\*)(\{(\w+):\s+(\{.*?\}|.*?)\})/) do |match|
        backslashes = "\\"* ($1.length / 2)
        if $1.length % 2 == 1
          backslashes + $2
        else
          self.logger.info { "Replacing tag #{match} in <#{node.recursive_value( 'dest' )}>" }
          processor = get_tag_processor $3
          processor.set_tag_config( YAML::load( "- #{$4}" )[0] )
          backslashes + substitute_tags( processor.process_tag( $3, node, refNode ), node, node )
        end
      end
      content
    end

    #######
    private
    #######

    # Returns the tag processor for +tag+ or throws an error if +tag+ is unkown.
    def get_tag_processor( tag )
      if @tags.has_key? tag
        return @tags[tag]
      elsif @tags.has_key? :default
        return @tags[:default]
      else
        raise Webgen::WebgenError.new( :UNKNOWN_TAG, tag )
      end
    end

  end


  # Base class for all tag plugins. The base class provides a default mechanism for retrieving
  # configuration data from either the configuration file or the tag itself. This behaviour can be
  # overridden in a subclass.
  class DefaultTag < UPS::Plugin

    Webgen::WebgenError.add_entry :TAG_PARAMETER_INVALID,
      "Invalid tag parameter configuration with type %0 (should be type %1) and value %2",
      "Add or correct the parameter value"


    # Sets the configuration parameters for the next #process_tag call. The configuration, if
    # specified, is taken from the tag itself.
    def set_tag_config( config )
      @curConfig = {}
      case config
      when Hash
        config.each do |key, value|
          if @defaultConfig.has_key? key
            @curConfig[key] = value
            self.logger.debug { "Setting parameter '#{key}' for tag #{self.class.const_get( :NAME )}" }
          else
            self.logger.warn { "Invalid parameter '#{key}' for tag #{self.class.const_get( :NAME )}" }
          end
        end
      when NilClass
        # ignore, no tag configuration
      else
        Webgen::WebgenError.new( :TAG_PARAMETER_INVALID, config.class.name, 'Hash or NilClass', config )
      end
    end


    # Default implementation for processing a tag.
    #
    # Has to be overridden by the subclass!!!
    def process_tag( tag, node, refNode )
      raise "not implemented"
    end

    #######
    private
    #######

    # Registers the configuration parameter +name+ for the tag. The Configuration plugin is used to
    # get the value for the parameter. If no value could be found, +defaultValue+ is used.
    def register_config_value( name, defaultValue )
      @defaultConfig ||= {}
      @defaultConfig[name] = UPS::Registry['Configuration'].get_config_value( self.class.const_get( :NAME ), name, defaultValue )
    end


    # Retrieves the parameter value for +name+. The value is taken from the current tag if the
    # parameter is specified there or the default value set in #register_config_value is used.
    def get_config_value( name )
      if !@curConfig.nil? && @curConfig.has_key?( name )
        return @curConfig[name]
      elsif @defaultConfig.has_key?( name )
        return @defaultConfig[name]
      else
        self.logger.error { "Referencing invalid configuration value '#{name}' in class #{self.class.name}" }
        return ''
      end
    end

  end

  UPS::Registry.register_plugin Tags

end
