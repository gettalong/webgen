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
require 'find'
require 'tsort'
require 'webgen/node'
require 'webgen/logging'

# Helper class for calculating plugin dependencies.
class Dependency < Hash
  include TSort

  alias tsort_each_node each_key
  def tsort_each_child(node, &block)
    fetch(node).each(&block)
  end
end


module Webgen

  VERSION = [0, 3, 0]
  SUMMARY = "Webgen is a templated based weg page generator."
  DESCRIPTION = "Webgen is a web page generator implemented in Ruby. " \
  "It is used to generate static web pages from templates and page " \
  "description files."

  # Base class for all plugins.
  class Plugin

    # Holds the plugin data from each and every plugin.
    @@config = {}

    def self.inherited( klass )
      (@@config[klass.name] = OpenStruct.new).klass = klass
    end

    ['plugin', 'summary', 'description'].each do |name|
      self.module_eval "def self.#{name}( obj ); @@config[self.name].#{name} = obj; end"
    end

    # Return plugin data
    def self.config
      @@config
    end

    # Add a dependency to the plugin. Dependencies are instantiated before the plugin gets
    # instantiated.
    def self.depends_on( *dep )
      dep.each {|d| (@@config[self.name].dependencies ||= []) << d}
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
      classes = self.class.ancestors[0..-3].delete_if {|c| c.instance_of?( Module ) }
      while klass = classes.shift
        data = @@config[klass.name]
        return data.params[name].value unless data.params.nil? || data.params[name].nil?
      end
      logger.error { "Referencing invalid configuration value '#{name}' in class #{self.class.name}" }
      return nil
    end

    # Set parameter +name+.
    def []=( name, value )
      self.class.set_param( @@config[self.class.name].plugin, name, value )
    end
    alias get_param []

    # Checks if the plugin has a parameter +name+.
    def has_param?( name )
      !@@config[self.class.name].params.nil? && @@config[self.class.name].params.has_key?( name )
    end

  end


  # Responsible for loading the other plugin files and holds the basic configuration options.
  class Configuration < Plugin

    plugin "Configuration"
    summary "Responsible for loading the configuration data"

    add_param 'srcDirectory', 'src', 'The directory from which the source files are read.'
    add_param 'outDirectory', 'output', 'The directory to which the output files are written.'
    add_param 'verbosityLevel', 3, 'The level of verbosity for the output of messages on the standard output.'
    add_param 'lang', 'en', 'The default language.'
    add_param 'configfile', 'config.yaml', 'The file from which extra configuration data is taken.'
    add_param 'logfile', 'webgen.log', 'The name of the log file if the log should be written to a file.'

    # Does all the initialisation stuff
    def init_all( data )
      load_plugins( File.dirname( __FILE__) + '/plugins', File.dirname( __FILE__).sub(/webgen$/, '') )
      parse_config_file
      data.each {|k,v| Plugin['Configuration'][k] = v}
      logger.level = get_param( 'verbosityLevel' )
      init_plugins
      Plugin['Tag Loader'].parse_config_file
    end

    # Parse config file and load the configuration values.
    def parse_config_file
      if File.exists?( get_param( 'configfile' ) )
        @pluginData = YAML::load( File.new( get_param( 'configfile' ) ) )
        @pluginData.each {|plugin, params| params.each {|name,value| Plugin.set_param( plugin, name, value ) } }
      else
        logger.info { "Config file <#{get_param( 'configfile' )}> does not exist, not extra configuration data read." }
      end
    end

    # Load all plugins in the given +path+. Before +require+ is actually called the path is
    # trimmed: if +trimpath+ matches the beginning of the string, +trimpath+ is deleted from it.
    def load_plugins( path, trimpath )
      Find.find( path ) do |file|
        Find.prune unless File.directory?( file ) || (/.rb$/ =~ file)
        require file.gsub(/^#{trimpath}/, '') if File.file?( file )
      end
    end

    # Instantiate the plugins in the correct order, except the classes which have a constant
    # +VIRTUAL+.
    def init_plugins
      dep = Dependency.new
      Plugin.config.each {|k,data| dep[data.plugin] = data.dependencies || []}
      dep.tsort.each do |plugin|
        data = Plugin.config.find {|k,v| v.plugin == plugin }[1]
        self.logger.debug { "Creating plugin of class #{data.klass.name}" }
        data.obj ||= data.klass.new unless data.klass.const_defined?( 'VIRTUAL' )
      end
    end

    # Set the log device to the logfile.
    def set_log_dev_to_logfile
      logger.set_log_dev( File.open( get_param( 'logfile' ), 'a' ) )
    end

  end

  # Initialize single configuration instance
  Plugin.config[Configuration.name].obj = Configuration.new

end


