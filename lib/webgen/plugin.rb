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

require 'find'
require 'yaml'
require 'ostruct'
require 'logger'
require 'tsort'

class OpenStruct
  public :table #:nodoc:#
end


module Webgen

  # Base module for all plugins. This module should be included by classes which need to derive from
  # an existing class but also need the power of the plugin system. If a class does not have any
  # base class, it is better to derive it from Webgen::Plugin instead of including this module.
  module PluginDefs

    # All the methods of this module become class methods in the classes which include the
    # PluginDefs module.
    module ClassMethods

      # Add subclass to plugin data.
      def inherited( klass )
        ClassMethods.extended( klass )
      end

      # Called when PluginDefs is included in another class. Add this class to plugin data.
      def self.extended( klass )
        callcc {|cont| throw :plugin_class_found, [cont, klass]}
        klass.init_config
      rescue NameError => e
        raise "Plugin '#{klass}' managed by no PluginLoader"
      end

      # Initializes the plugin configuration structure.
      def init_config
        @config = OpenStruct.new
        @config.plugin_klass = self
        @config.params = {}
        @config.infos = {}
        @config.dependencies = []
      end

      # Returns the configuration structure for the plugin.
      def config
        @config
      end

      # Sets general information about the plugin (summary text, description, ...). The parameter
      # has to be a Hash.
      def infos( param )
        self.config.infos.update( param )
      end

      # Add a dependency to the plugin. Dependencies are instantiated before the plugin gets
      # instantiated.
      def depends_on( *dep )
        dep.each {|d| self.config.dependencies << ( Class === d && d.ancestors.include?( PluginDefs ) ? d.name : d )}
      end

      # Defines a parameter.The parameter can be changed in the configuration file later.
      #
      # Arguments:
      # +name+:: the name of the parameter
      # +default+:: the default value of the parameter
      # +description+:: a small description of the parameter
      # +changeHandler+:: optional, method/proc which is invoked every time the parameter is changed.
      #                   Handler signature: changeHandler( paramName, oldValue, newValue )
      def param( name, default, description, changeHandler = nil )
        data = OpenStruct.new( :name => name, :default => default,
                               :description => description, :changeHandler => changeHandler )
        self.config.params[name] = data
      end

      # Returns the ancestor classes for the object's class which are sub classes from Plugin.
      def ancestor_classes
        ancestors.delete_if {|c| c.instance_of?( Module ) }[0..-3]
      end

      # TODO(remove?) Defines a new *handler class. The methods creates two methods based on the parameter +name+:
      # - klass.register_[name]
      # - object.get_[name]
      def define_handler( name )
        s = "def self.register_#{name}( param )
        (Webgen::Plugin.config[#{self.name}].#{name}s ||= {})[param] = self
        Webgen::Plugin.config[self].registered_#{name} = param
      end\n"
        s += "def get_#{name}( param )
        if Webgen::Plugin.config[#{self.name}].#{name}s.has_key?( param )
          Webgen::Plugin.config[Webgen::Plugin.config[#{self.name}].#{name}s[param]].obj
        else
           Webgen::Plugin.config[#{self.name}].obj
        end
      end"
        module_eval s
      end

    end

    # Appends the methods of this module as object methods to the including class and the methods
    # defined in the module ClassMethods as class methods.
    def self.append_features( klass )
      super
      klass.extend( ClassMethods )
    end

    # Assigns the PluginManager used for the plugin instance.
    def initialize( plugin_manager )
      @plugin_manager = plugin_manager
    end

    # Returns the parameter +name+ for the plugin. If +plugin+ is specified, the parameter +name+
    # for the plugin +plugin+ is returned.
    def []( name, plugin = nil)
      @plugin_manager.param_for_plugin( plugin || self.class, name )
    end
    alias param []

    # Logs the the result of +block+ using the severity level +sev_level+.
    def log( sev_level, &block )
      source = self.class.name + '#' + caller[0][Regexp.new("`.*'")][1..-2]
      @plugin_manager.log_msg( sev_level, source, &block )
    end

  end


  # Responsible for loading plugins. Each PluginLoader has an array of plugins which it loaded.
  # Several methods for loading plugins are available.
  class PluginLoader

    # The plugins loaded by this PluginLoader instance.
    attr_reader :plugins

    # Creates a new PluginLoader instance.
    def initialize
      @plugins = []
    end

    # Loads all plugins in the given +dir+ and in its subdirectories. Before +require+ is actually
    # called the path is trimmed: if +trimpath+ matches the beginning of the string, +trimpath+ is
    # deleted from it.
    def load_from_dir( dir, trimpath = '')
      Find.find( dir ) do |file|
        trimmedFile = file.gsub(/^#{trimpath}/, '')
        Find.prune unless File.directory?( file ) || ( (/\.rb$/ =~ file) && !$".include?( trimmedFile ) )
        load_from_file( trimmedFile ) if File.file?( file ) && /\.rb$/ =~ file
      end
    end

    # Loads all plugins specified in the +file+.
    def load_from_file( file )
      load_from_block { require file }
    end

    # Loads all plugins which get declared in the given block.
    def load_from_block
      cont, klass = catch( :plugin_class_found ) do
        yield
        nil # return value for catch, means: all classes processed
      end
      add_plugin_class( klass ) unless klass.nil?
      cont.call if cont
    end

    # Checks if this PluginLoader has loaded a plugin called +name+.
    def has_plugin?( name )
      plugin_for_name( name ) != nil
    end

    # Returns the plugin called +name+ or +nil+ if it is not found.
    def plugin_for_name( name )
      @plugins.find {|p| p.name == name}
    end

    #######
    private
    #######

    def add_plugin_class( klass )
      @plugins << klass if klass != Webgen::Plugin && klass != Webgen::CommandPlugin
    end

  end


  # Raised when a plugin which should have been loaded was not loaded.
  class PluginNotFound < RuntimeError

    attr_reader :name

    def initialize( name )
      @name = name
    end

    def message
      "Plugin '#{@name}' needed, but it was not loaded"
    end

  end


  # Raised when a parameter for a plugin does not exist.
  class PluginParamNotFound < RuntimeError

    def initialize( plugin, param )
      @plugin = plugin
      @param = param
    end

    def message
      "Could not find parameter '#{@param}' for plugin '#{@plugin}'"
    end

  end


  # Helper class for calculating plugin dependencies.
  class DependencyHash < Hash
    include TSort

    alias tsort_each_node each_key
    def tsort_each_child(node, &block)
      fetch(node).each(&block)
    end
  end


  # Once plugin classes are loaded, they are ready to get used. This class is used for instantiating
  # plugins and their dependencies in the correct order and provide the plugins the facility for
  # retrieving current parameter values.
  class PluginManager

    # A hash of all instantiated plugins.
    attr_reader :plugins

    # Define which plugins should get instantiated.
    attr_reader :plugin_classes

    # Used for plugin dependency resolution.
    attr_reader :plugin_loaders

    # Used for retrieving current plugin parameter values.
    attr_accessor :plugin_config

    # The logger used by the instance and the plugin objects.
    attr_accessor :logger

    # Creates a new PluginManager instance.
    def initialize( plugin_loaders = [], plugin_classes = [] )
      @logger = nil
      @plugins = {}
      @plugin_classes = []
      @plugin_loaders = plugin_loaders
      @plugin_config = nil
      add_plugin_classes( plugin_classes )
    end

    # Adds all Plugin classes in the array +plugins+ and their dependencies.
    def add_plugin_classes( plugins )
      deps = dependent_plugins( plugins )
      @plugin_classes += plugins + deps
      @plugin_classes.uniq!
    end

    # Instantiates the plugins in the correct order, except the classes which have the plugin info
    # +:instantiate+ set to +false+.
    def init
      @plugins = {}
      dep = DependencyHash.new
      @plugin_classes.each {|plugin| dep[plugin.name] = plugin.config.dependencies }
      dep.tsort.each do |plugin_name|
        config = plugin_class_by_name( plugin_name ).config
        unless config.infos.has_key?(:instantiate) && !config.infos[:instantiate]
          log_msg( :debug, 'PluginManager#init') { 'Creating plugin of class #{config.plugin_klass.name}' }
          @plugins[config.plugin_klass.name] = config.plugin_klass.new( self )
        end
      end
    end

    # Returns the plugin instance for +plugin+. +plugin+ can either be a plugin class or the name of
    # a plugin.
    def []( plugin )
      ( plugin.kind_of?( Class ) ? @plugins[plugin.name] : @plugins[plugin] )
    end

    # Returns the parameter +param+ for the +plugin_name+.
    def param_for_plugin( plugin_name, param )
      plugin = ( plugin_name.kind_of?( String ) ?
                 plugin_class_by_name( plugin_name ) :
                 plugin_class_by_name( plugin_name.name ) )
      raise PluginParamNotFound.new( plugin_name, param ) if plugin.nil?

      value_found = false
      value = nil
      plugin.ancestor_classes.each do |plugin_klass|
        begin
          value = get_plugin_param_value( plugin_klass, param )
          value_found = true
          break
        rescue PluginParamNotFound
        end
      end

      if value_found
        value
      else
        raise PluginParamNotFound.new( plugin.name, param )
      end
    end

    # Logs the result of executing +block+ under the severity level +sev_level+. The parameter
    # +source+ identifies the source of the log message.
    def log_msg( sev_level, source, &block )
      @logger.send( sev_level, source, &block ) if @logger
    end

    #######
    private
    #######

    def plugin_class_by_name( name )
      @plugin_classes.find {|p| p.name == name}
    end

    def dependent_plugins( classes )
      deps = []
      classes.each do |plugin|
        plugin.config.dependencies.each do |dep|
          p = nil
          @plugin_loaders.each {|loader| p = loader.plugin_for_name( dep ); break unless p.nil? }
          if p.nil?
            raise PluginNotFound.new( dep )
          else
            deps << p unless deps.include?( p )
          end
        end
      end
      deps
    end

    def get_plugin_param_value( plugin, param )
      raise PluginParamNotFound.new( plugin.name, param ) unless plugin.config.params.has_key?( param )

      value_found = false
      if @plugin_config
        begin
          value = @plugin_config.param_for_plugin( plugin.name, param )
          value_found = true
        rescue PluginParamNotFound
        end
      end

      value = plugin.config.params[param].default unless value_found
      value
    end

  end


  # Used for logging the messages of plugin instances.
  class Logger < ::Logger

    def initialize( logdev = STDERR )
      super( logdev, 0, 0 )
      self.level = ::Logger::ERROR
      self.formatter = Proc.new do |severity, timestamp, progname, msg|
        "%s %5s -- %s: %s\n" % [timestamp, severity, progname, msg ]
      end
    end

  end

end



module Webgen

  # Default PluginLoader instance responsible for loading all plugins shipped with webgen.
  DEFAULT_PLUGIN_LOADER = PluginLoader.new

  DEFAULT_PLUGIN_LOADER.load_from_block do

    module CommandPlugin; end

    # The base class for all plugins.
    class Plugin

      include PluginDefs

    end


    # This module should be included by classes derived from CommandParser::Command as it
    # automatically adds an object of the class to the main CommandParser object.
    module CommandPlugin

      include PluginDefs

      def self.append_features( klass )
        super
        PluginDefs.append_features( klass )
        klass.extend( ClassMethods ) #TODO necessary? -> already called in PluginDefs.append_features
      end
    end

  end

  #TODO load all webgen plugins here into DEFAULT_PLUGIN_LOADER
end
