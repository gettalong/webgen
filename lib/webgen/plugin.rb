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
require 'webgen/config'

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
        @config.plugin_name = self.name.sub(/^(#<.*?>|Webgen::DEFAULT_WRAPPER_MODULE)::/,'').sub('::','/')
        @config.params = {}
        @config.infos = {}
        @config.dependencies = []
      end

      # Returns the configuration structure for the plugin.
      def config
        @config
      end

      # Sets the name of the plugin if the parameter +name+ is specified. Otherwise the plugin name
      # is returned. If the plugin name is not set, a default name is used.
      def plugin_name( name = nil )
        (name.nil? ? @config.plugin_name : @config.plugin_name = name)
      end

      # Sets general information about the plugin (summary text, description, ...). The parameter
      # has to be a Hash.
      def infos( param )
        self.config.infos.update( param )
      end

      # Add a dependency to the plugin, ie. the name of another plugin. Dependencies are
      # instantiated before the plugin gets instantiated.
      def depends_on( *dep )
        dep.each {|d| self.config.dependencies << d}
      end

      # Defines a parameter.The parameter can be changed in the configuration file later.
      #
      # Arguments:
      # +name+:: the name of the parameter
      # +default+:: the default value of the parameter
      # +description+:: a small description of the parameter
      def param( name, default, description )
        data = OpenStruct.new( :name => name, :default => default, :description => description )
        self.config.params[name] = data
      end

      # Returns the ancestor classes for the object's class which are sub classes from Plugin.
      def ancestor_classes
        ancestors.delete_if {|c| c.instance_of?( Module ) }[0..-3]
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
      source = self.class.plugin_name + '#' + caller[0][Regexp.new("`.*'")][1..-2]
      @plugin_manager.log_msg( sev_level, source, &block )
    end

  end

  class ::Object

    def load_plugin( file )
      file = file + '.rb' unless /\.rb$/ =~ file
      wrapper, do_load = callcc {|cont| throw :load_plugin_file?, [cont, file]}

      realfile = file
      if /^(\/|\w:)/ !~ realfile
        $:.each do |path|
          realfile = File.join( path, file )
          break if File.exists?( realfile )
        end
      end

      wrapper.module_eval( File.read( realfile ), file, 1 ) if do_load
    end

  end

  # Responsible for loading plugins classes. Each PluginLoader has an array of plugin classes which
  # it loaded. Several methods for loading plugins classes are available.
  class PluginLoader

    # The plugin classes loaded by this PluginLoader instance.
    attr_reader :plugin_classes

    # Creates a new PluginLoader instance. The +wrapper_module+ is used when loading the plugins so
    # that they do not pollute the global namespace.
    def initialize( wrapper_module = Module.new )
      @plugin_classes = []
      @loaded_files = []
      @wrapper_module = wrapper_module
    end

    # Loads all plugin classes in the given +dir+ and in its subdirectories. Before +require+ is
    # actually called the path is trimmed: if +trimpath+ matches the beginning of the string,
    # +trimpath+ is deleted from it.
    def load_from_dir( dir, trimpath = '')
      Find.find( dir ) do |file|
        trimmedFile = file.gsub(/^#{trimpath}/, '')
        Find.prune unless File.directory?( file ) || (/\.rb$/ =~ file)
        load_from_file( trimmedFile ) if File.file?( file ) && /\.rb$/ =~ file
      end
    end

    # Loads all plugin classes specified in the +file+.
    def load_from_file( file )
      load_from_block do
        cont, file = catch( :load_plugin_file? ) do
          load_plugin( file )
          nil
        end
        do_load_file = !@loaded_files.include?( file ) unless file.nil?
        @loaded_files << file unless file.nil? || @loaded_files.include?( file )
        cont.call( @wrapper_module, do_load_file ) if cont
      end
    end

    # Loads all plugin classes which get declared in the given block.
    def load_from_block( &block )
      cont, klass = catch( :plugin_class_found ) do
        yield
        nil # return value for catch, means: all classes processed
      end
      add_plugin_class( klass ) unless klass.nil?
      cont.call if cont
      sort_out_base_plugins
    end

    # Checks if this PluginLoader has loaded a plugin called +name+.
    def has_plugin?( name )
      plugin_class_for_name( name ) != nil
    end

    # Returns the plugin class called +name+ or +nil+ if it is not found.
    def plugin_class_for_name( name )
      @plugin_classes.find {|p| p.plugin_name == name}
    end

    #######
    private
    #######

    def add_plugin_class( klass )
      @plugin_classes << klass
    end

    def sort_out_base_plugins
      @plugin_classes.delete_if {|klass| klass.config.infos[:is_base_plugin] == true}
    end

  end


  # Raised when a plugin which should have been loaded was not loaded.
  class PluginNotFound < RuntimeError

    attr_reader :name
    attr_reader :needed_by

    def initialize( name, needed_by )
      @name = name
      @needed_by = needed_by
    end

    def message
      "Plugin '#{@name}' needed by '#{@needed_by}', but it was not loaded"
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

    # Used for retrieving current plugin parameter values. Should be set before calling #init.
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
      @plugin_classes.each {|plugin| dep[plugin.plugin_name] = plugin.config.dependencies }
      dep.tsort.each do |plugin_name|
        config = plugin_class_for_name( plugin_name ).config
        unless config.infos.has_key?(:instantiate) && !config.infos[:instantiate]
          log_msg( :debug, 'PluginManager#init') { "Creating plugin of class #{config.plugin_name}" }
          @plugins[config.plugin_name] = config.plugin_klass.new( self )
        end
      end
    end

    # Returns the plugin instance for +plugin+. +plugin+ can either be a plugin class or the name of
    # a plugin.
    def []( plugin )
      ( plugin.kind_of?( Class ) ? @plugins[plugin.plugin_name] : @plugins[plugin] )
    end

    # Returns the parameter +param+ for the +plugin_name+.
    def param_for_plugin( plugin_name, param )
      plugin = ( plugin_name.kind_of?( String ) ?
                 plugin_class_for_name( plugin_name ) :
                 plugin_class_for_name( plugin_name.plugin_name ) )
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

    # Returns the plugin class for the plugin +plugin_name+.
    def plugin_class_for_name( plugin_name )
      @plugin_classes.find {|p| p.plugin_name == plugin_name}
    end

    # Logs the result of executing +block+ under the severity level +sev_level+. The parameter
    # +source+ identifies the source of the log message.
    def log_msg( sev_level, source, &block )
      @logger.send( sev_level, source, &block ) if @logger
      nil
    end

    #######
    private
    #######

    def dependent_plugins( classes )
      deps = []
      classes.each do |plugin|
        plugin.config.dependencies.each do |dep|
          p = nil
          @plugin_loaders.each {|loader| p = loader.plugin_class_for_name( dep ); break unless p.nil? }
          if p.nil?
            raise PluginNotFound.new( dep, plugin.plugin_name )
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
          value = @plugin_config.param_for_plugin( plugin.plugin_name, param )
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
        if self.level == ::Logger::DEBUG
          "%5s -- %s: %s\n" % [severity, progname, msg ]
        else
          "%5s -- %s\n" % [severity, msg]
        end
      end
    end

  end

end



module Webgen

  # Default PluginLoader instance responsible for loading all plugins shipped with webgen.
  DEFAULT_WRAPPER_MODULE = Module.new
  DEFAULT_PLUGIN_LOADER = PluginLoader.new( DEFAULT_WRAPPER_MODULE )

  DEFAULT_PLUGIN_LOADER.load_from_block do

    # THE base class for all plugins.
    class Plugin

      include PluginDefs

      infos :is_base_plugin => true

    end

    #TODO better comment and document methods: Base class for plugins which are super classes of
    #plugins that handle different types of a simliar kind. E.g. different markup to HTML
    #converters.
    class HandlerPlugin < Plugin

      infos :is_base_plugin => true

      def self.register_handler( name )
        self.config.infos[:handler_for] = name
      end

      def self.registered_handler
        self.config.infos[:handler_for]
      end

      def registered_handlers
        if !defined?( @registered_handlers_cache ) || @cached_plugins_hash != @plugin_manager.plugins.keys.hash
          @registered_handlers_cache = {}
          @plugin_manager.plugins.each do |name, plugin|
            if plugin.kind_of?( self.class ) && plugin.class.registered_handler
              @registered_handlers_cache[plugin.class.registered_handler] = plugin
            end
          end
          @cached_plugins_hash = @plugin_manager.plugins.keys.hash
        end
        @registered_handlers_cache
      end

    end

    # This module should be included by classes derived from CommandParser::Command as it
    # automatically adds an object of the class to the main CommandParser object. However, the
    # +super+ call in the +initialize+ method calls the method from PluginDefs, you need to call
    # +superclass_init+ to call the original +initialize+ method from the super class.
    module CommandPlugin

      def self.append_features( klass )
        klass.instance_eval {alias_method( :superclass_initialize, :initialize )}
        super
        PluginDefs.append_features( klass )
      end

    end

  end

  # Set this constant to +false+ before requiring the file to not load the default plugins.
  LOAD_DEFAULT_PLUGINS = true unless defined?( LOAD_DEFAULT_PLUGINS )

  DEFAULT_PLUGIN_LOADER.load_from_dir( File.join( File.dirname( __FILE__ ), 'plugins' ),
                                       File.dirname( __FILE__ ).sub( /webgen$/, '' ) ) if LOAD_DEFAULT_PLUGINS

end
