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
  class Tags < Webgen::Plugin

    NAME = "Tags"
    SHORT_DESC = "Super plugin for handling tags"

    # Tag plugins should add an entry to this hash.
    attr_reader :tags

    def initialize
      @tags = Hash.new
    end


    # Substitutes all references to tags in the string +content+. The +node+ parameter specifies the
    # tree node the content of which is used. The +refNode+ parameter specifies relative to which
    # all references should be resolved.
    def substitute_tags( content, node, refNode )
      if !content.kind_of? String
        self.logger.error { "The content in <#{refNode.recursive_value( 'src' )}> is not a string, but a #{content.class.name}" }
        content = content.to_s
      end
      return replace_tags( content ) do |tag, data|
        self.logger.info { "Replacing tag #{tag} with data '#{data}' in <#{node.recursive_value( 'dest' )}>" }
        processor = get_tag_processor tag
        processor.set_tag_config( YAML::load( "- #{data}" )[0], refNode )
        output = processor.process_tag( tag, node, refNode )
        processor.reset_tag_config
        output = substitute_tags( output, node, node ) if processor.processOutput
        output
      end
    end

    #######
    private
    #######

    # Scans the +content+ for tags. If a tag is found, the block is called which needs to return the
    # value for the given tag. The changed content is returned.
    def replace_tags( content ) # :yields: tag, data
      offset = 0;
      while index = content.index( /(\\*)\{(\w+):/, offset )
        bracketCount = 1;
        length = $1.length + 1;
        content[(index + length)..-1].each_byte do |char|
          length += 1
          bracketCount += 1 if char == ?{
          bracketCount -= 1 if char == ?}
          break if bracketCount == 0
        end

        if bracketCount > 0
          self.logger.error { "Unbalanced curly brackets!!!" }
          newContent = content[index, length]
        else
          newContent = "\\"* ( $1.length / 2 )
          if $1.length % 2 == 1
            newContent += content[index + $1.length, length - $1.length]
          else
            tagHeaderLength = $1.length + $2.length + 2
            newContent += yield( $2, content[index + tagHeaderLength, length - tagHeaderLength - 1] )
          end
          content[index, length] = newContent
        end
        offset = index + newContent.length
      end
      content
    end


    # Returns the tag processor for +tag+ or throws an error if +tag+ is unkown.
    def get_tag_processor( tag )
      if @tags.has_key? tag
        return @tags[tag]
      elsif @tags.has_key? :default
        return @tags[:default]
      else
        self.logger.error { "No tag processor for tag '#{tag}' found" }
        return DefaulTag.new
      end
    end

  end


  # Base class for all tag plugins. The base class provides a default mechanism for retrieving
  # configuration data from either the configuration file or the tag itself. This behaviour can be
  # overridden in a subclass.
  class DefaultTag < Webgen::Plugin

    # +true+, if the output should be processed again
    attr_reader :processOutput

    def initialize
      @processOutput = true
    end

    def init
      if self.class.const_defined? :TAG_NAME
        UPS::Registry[Tags::NAME].tags[self.class::TAG_NAME] = self
      end
    end

    # Sets the configuration parameters for the next #process_tag call. The configuration, if
    # specified, is taken from the tag itself.
    def set_tag_config( config, node )
      @curConfig = {}
      case config
      when Hash
        set_cur_config( config, node )

      when Array
        config.each do |item|
          set_cur_config( item, node ) if item.kind_of? Hash
        end
        config = config.delete_if do |item| item.kind_of? Hash end
        config = config[0] if config.length == 1
        set_mandatory_config( config, node )

      when String
        set_mandatory_config( config, node )

      when NilClass
        if self.class.method_defined? :check_mandatory_param
          self.logger.error { "Mandatory parameter for tag '#{self.class.name}' in <#{node.recursive_value( 'src' )}> not specified" }
        end

      else
        self.logger.error { "Invalid parameter for tag '#{self.class.name}' in <#{node.recursive_value( 'src' )}>" }
      end
    end


    # Resets the tag configuration data.
    def reset_tag_config
      @curConfig = {}
    end


    # Default implementation for processing a tag.
    #
    # Has to be overridden by the subclass!!!
    def process_tag( tag, node, refNode )
      ''
    end

    #######
    private
    #######

    attr_writer :processOutput


    # Sets the current configuration taking values from +config+ which has to be a Hash.
    def set_cur_config( config, node )
      config.each do |key, value|
        if defined?( @config ) && @config.has_key?( key )
          @curConfig[key] = value
          self.logger.debug { "Setting parameter '#{key}' for tag '#{self.class::NAME}' in <#{node.recursive_value( 'src' )}>" }
        else
          self.logger.warn { "Invalid parameter '#{key}' for tag '#{self.class::NAME}' in <#{node.recursive_value( 'src' )}>" }
        end
      end
    end


    # Sets the mandatory parameter (key = :mandatory).
    def set_mandatory_config( config, node )
      if self.class.method_defined? :check_mandatory_param
        if check_mandatory_param config
          @curConfig[:mandatory] = config
        else
          self.logger.error { "Invalid mandatory parameter for tag '#{self.class::NAME}' in <#{node.recursive_value( 'src' )}>"}
        end
      else
        self.logger.info { "Unused tag parameters specified for tag '#{self.class::NAME}' in <#{node.recursive_value( 'src' )}>" }
      end
    end


    # Retrieves the parameter value for +name+. The value is taken from the current tag if the
    # parameter is specified there or the default value set in #register_config_value is used.
    def get_config_param( name )
      if !@curConfig.nil? && @curConfig.has_key?( name )
        return @curConfig[name]
      else
        super name
      end
    end

  end

  UPS::Registry.register_plugin Tags

end
