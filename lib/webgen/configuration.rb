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
require 'ostruct'
require 'webgen/logging'
require 'find'

module Webgen

  VERSION = [0, 2, 1]
  SUMMARY = "Webgen is a templated based weg page generator."
  DESCRIPTION = "Webgen is a web page generator implemented in Ruby. " \
  "It is used to generate static web pages from templates and page " \
  "description files."

  # Base class for all plugins.
  class Plugin

    # Holds the plugin data from each and every plugin.
    @@config = {}

    def self.inherited( klass )
      (@@config[klass.name] = OpenStruct.new).obj = klass.new unless klass.const_defined?( 'VIRTUAL' )
    end

    ['plugin', 'summary', 'description'].each do |name|
      self.module_eval "def self.#{name}( obj ); @@config[self.name].#{name} = obj; end"
    end

    # Return plugin data
    def self.config
      @@config
    end

    # Shortcut for getting the plugin with the name +name+.
    def self.[]( name )
      @@config.find {|k,v| v.plugin == name }[1].obj
    end

    # Add a parameter for the current class. Has to be used by subclasses to define their parameters!
    #
    # Arguments:
    # +name+:: the name of the parameter
    # +default+:: the default value of the parameter
    # +description+:: a small description of the parameter
    def self.add_param( name, default, description )
      self.logger.debug { "Adding parameter #{name} for plugin class #{self.name}" }
      data = OpenStruct.new( :name => name, :value => default, :default => default, :description => description )
      (@@config[self.name].params ||= {})[name] = data
    end

    # Set parameter +name+ for +plugin+ to +value+.
    def self.set_param( plugin, name, value )
      logger.debug { "Setting parameter #{name} for plugin #{plugin} to #{value.inspect}" }
      klass, item = @@config.find {|k,v| v.plugin == plugin }
      if !item.nil? && !item.params.nil? && item.params.has_key?( name )
        item.params[name].value = value
      else
        logger.error { "Cannot set undefined parameter '#{name}' for plugin '#{plugin}'" }
      end
    end

    # Return parameter +name+.
    def []( name )
      data = @@config[self.class.name]
      unless data.params.nil? || data.params[name].nil?
        return data.params[name].value
      else
        logger.error { "Referencing invalid configuration value '#{name}' in class #{self.class.name}" }
        return nil
      end
    end

    # Set parameter +name+.
    def []=( name, value )
      self.class.set_param( @@config[self.class.name].plugin, name, value )
    end

    alias get_param []

  end


  class Configuration < Plugin

    plugin "Configuration"
    summary "Responsible for loading the configuration data"

    add_param 'srcDirectory', 'src', 'The directory from which the source files are read.'
    add_param 'outDirectory', 'output', 'The directory to which the output files are written.'
    add_param 'verbosityLevel', 3, 'The level of verbosity for the output of messages on the standard output.'
    add_param 'lang', 'en', 'The default language.'
    add_param 'configfile', 'config.yaml', 'The file from which extra configuration data is taken'

    def initialize
      @homeDir = File.dirname( $0 )
    end

    # Parse config file and load the configuration values.
    def parse_config_file
      if File.exists?( get_param( 'configfile' ) )
        @pluginData = YAML::load( File.new( get_param( 'configfile' ) ) )
        @pluginData.each {|plugin, params| params.each {|name,value| Plugin.set_param( plugin, name, value ) } }
        logger.level = get_param( 'verbosityLevel' )
      else
        logger.info { "Config file <#{get_param( 'configfile' )}> does not exist, not extra configuration data read." }
      end
    end

    # Loads all plugins in the given +path+. Before +require+ is actually called the path is
    # trimmed: if +trimpath+ matches the beginning of the string, +trimpath+ is deleted from it.
    def load_plugins( path, trimpath )
      Find.find( path ) do |file|
        Find.prune unless File.directory?( file ) || (/.rb$/ =~ file)
        require file.gsub(/^#{trimpath}/, '') if File.file? file
      end
    end

    def load_file_outputter
      logger.set_log_dev( File.open( 'webgen.log', 'a' ) )
    end

  end


  class Logger < ::Logger

    def initialize( dev )
      super( dev )
      self.datetime_format = "%Y-%m-%d %H:%M:%S"
    end

    def format_message( severity, timestamp, msg, progname )
      "%s %s -- %s: %s\n" % [timestamp, severity, progname, msg ]
    end

    def set_log_dev( dev )
      @logdev = LogDevice.new( dev )
    end

  end

end


