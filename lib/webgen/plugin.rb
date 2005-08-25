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
require 'ostruct'

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

      # Holds the plugin data from each and every plugin.
      @@config = {}
      @@configFileData = {}

      # Reloads the configuration file data.
      def load_config_file
        @@configFileData = ( File.exists?( 'config.yaml' ) ? YAML::load( File.new( 'config.yaml' ) ) : {} )
        @@configFileData = {} unless @@configFileData.kind_of?( Hash )
        @@configFileData.each do |pluginName, params|
          next if (pair = @@config.find {|pluginKlass, data| data.plugin == pluginName}).nil?
          if params.kind_of?( Hash ) && !pair[1].params.nil?
            pair[1].params.each do |name, value|
              set_param( pluginName, name, params[name] ) if params.has_key?( name )
            end
          end
        end
      end

      # Reset the configuration data. The configuration has to be initialized again.
      def reset_config_data
        @@config.each do |pluginKlass, data|
          if pluginKlass != Logging && pluginKlass != Configuration
            data.obj = nil
          end
          data.params.each {|name, p| set_param( data.plugin, name, p.default ) } if data.params
        end
        load_config_file
      end

      # Return plugin data
      def config
        @@config
      end

      # Shortcut for getting the plugin with the name +name+.
      def []( name )
        pair = @@config.find {|k,v| v.plugin == name }
        self.logger.warn { "Could not retrieve plugin '#{name}' as such a plugin does not exist!" } if pair.nil?
        pair[1].obj unless pair.nil?
      end

      # Add subclass to plugin data.
      def inherited( klass )
        ClassMethods.extended( klass )
      end

      # Called when PluginDefs is included in another class. Add this class to plugin data.
      def self.extended( klass )
        if (klass != Webgen::Plugin) && (klass != Webgen::CommandPlugin)
          (@@config[klass] = OpenStruct.new).klass = klass
          @@config[klass].plugin = klass.name.split( /::/ ).last
        end
      end

      ['summary', 'description'].each do |name|
        module_eval "def #{name}( obj ); @@config[self].#{name} = obj; end"
      end


      # Add a dependency to the plugin. Dependencies are instantiated before the plugin gets
      # instantiated.
      def depends_on( *dep )
        dep.each {|d| (@@config[self].dependencies ||= []) << d}
      end

      # Specify which meta information entries are used by the plugin.
      def used_meta_info( *names )
        names.each {|n| (@@config[self].used_meta_info ||= []) << n }
      end

      # Add a parameter for the current class. Has to be used by subclasses to define their parameters!
      #
      # Arguments:
      # +name+:: the name of the parameter
      # +default+:: the default value of the parameter
      # +description+:: a small description of the parameter
      # +changeHandler+:: optional, method/proc which is invoked every time the parameter is changed.
      #                   Handler signature: changeHandler( paramName, oldValue, newValue )
      def add_param( name, default, description, changeHandler = nil )
        self.logger.debug { "Adding parameter '#{name}' for plugin class '#{self.name}'" }
        if @@configFileData.kind_of?( Hash ) && @@configFileData.has_key?( @@config[self].plugin ) \
          && @@configFileData[@@config[self].plugin].kind_of?( Hash ) && @@configFileData[@@config[self].plugin].has_key?( name )
          curval = @@configFileData[@@config[self].plugin][name]
          self.logger.debug { "Using configured value for parameter #{@@config[self].plugin} -> #{name}" }
        else
          curval = default
        end
        data = OpenStruct.new( :name => name, :value => curval, :default => default, :description => description, :changeHandler => changeHandler )
        (@@config[self].params ||= {})[name] = data
        changeHandler.call( name, default, curval ) if changeHandler
      end

      # Set parameter +name+ for +plugin+ to +value+.
      def set_param( plugin, name, value )
        found = catch( :found ) do
          item = @@config.find {|k,v| v.plugin == plugin }[1]
          item.klass.ancestor_classes.each do |k|
            item = @@config[k]
            if !item.nil? && !item.params.nil? && item.params.has_key?( name )
              oldvalue = item.params[name].value
              item.params[name].value = value
              item.params[name].changeHandler.call( name, oldvalue, value ) if item.params[name].changeHandler
              logger.debug { "Set parameter '#{name}' for plugin '#{plugin}' to #{value.inspect}" }
              throw :found, true
            end
          end
        end
        logger.error { "Cannot set undefined parameter '#{name}' for plugin '#{plugin}'" } unless found
      end

      def get_param( name )
        ancestor_classes.each do |klass|
          data = @@config[klass]
          return data.params[name].value unless data.params.nil? || data.params[name].nil?
        end
        logger.error { "Referencing invalid configuration value '#{name}' in class #{self.name}" }
        return nil
      end

      # Defines a new *handler class. The methods creates two methods based on the parameter +name+:
      # - klass.register_[name]
      # - object.get_[name]
      def define_handler( name )
        s = "def self.register_#{name}( param )
        self.logger.info { \"Registering class \#{self.name} for handling #{name} '\#{param}'\" }
        (Webgen::Plugin.config[#{self.name}].#{name}s ||= {})[param] = self
        Webgen::Plugin.config[self].registered_#{name} = param
      end\n"
        s += "def get_#{name}( param )
        if Webgen::Plugin.config[#{self.name}].#{name}s.has_key?( param )
          Webgen::Plugin.config[Webgen::Plugin.config[#{self.name}].#{name}s[param]].obj
        else
          self.logger.error { \"Invalid #{name} specified: \#{param}! Using #{self.name}!\" }
           Webgen::Plugin.config[#{self.name}].obj
        end
      end"
        module_eval s
      end

      # Return the ancestor classes for the object's class which are sub classes from Plugin.
      def ancestor_classes
        ancestors.delete_if {|c| c.instance_of?( Module ) }[0..-3]
      end

    end

    def self.append_features( klass )
      super
      klass.extend( ClassMethods )
    end

    # Return parameter +name+.
    def []( name )
      self.class.get_param( name )
    end
    alias get_param []

    # Set parameter +name+.
    def []=( name, value )
      self.class.set_param( self.class.config[self.class].plugin, name, value )
    end

    # Checks if the plugin has a parameter +name+.
    def has_param?( name )
      self.class.ancestor_classes.any? do |klass|
        !self.class.config[klass].params.nil? && self.class.config[klass].params.has_key?( name )
      end
    end

  end

  module CommandPlugin; end

  # The base class for all plugins.
  class Plugin
    include PluginDefs

    load_config_file
  end

  # This module should be included by classes derived from CommandParser::Command as it
  # automatically adds an object of the class to the main CommandParser object.
  module CommandPlugin
    include PluginDefs

    def self.append_features( klass )
      super
      PluginDefs.append_features( klass )
      klass.extend( ClassMethods )
    end
  end

  require 'webgen/logging'
  require 'webgen/configuration'

end


