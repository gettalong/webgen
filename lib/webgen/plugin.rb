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

  # Base class for all plugins.
  class Plugin

    # Holds the plugin data from each and every plugin.
    @@config = {}
    @@configFileData = ( File.exists?( 'config.yaml' ) ? YAML::load( File.new( 'config.yaml' ) ) : {} )

    def self.inherited( klass )
      (@@config[klass] = OpenStruct.new).klass = klass
      @@config[klass].plugin = klass.name.split( /::/ ).last
    end

    ['summary', 'description'].each do |name|
      self.module_eval "def self.#{name}( obj ); @@config[self].#{name} = obj; end"
    end

    # Return plugin data
    def self.config
      @@config
    end

    # Add a dependency to the plugin. Dependencies are instantiated before the plugin gets
    # instantiated.
    def self.depends_on( *dep )
      dep.each {|d| (@@config[self].dependencies ||= []) << d}
    end

    # Shortcut for getting the plugin with the name +name+.
    def self.[]( name )
      pair = @@config.find {|k,v| v.plugin == name }
      self.logger.warn { "Could not retrieve plugin '#{name}' as such a plugin does not exist!" } if pair.nil?
      pair[1].obj unless pair.nil?
    end

    # Add a parameter for the current class. Has to be used by subclasses to define their parameters!
    #
    # Arguments:
    # +name+:: the name of the parameter
    # +default+:: the default value of the parameter
    # +description+:: a small description of the parameter
    # +changeHandler+:: optional, method/proc which is invoked every time the parameter is changed.
    #                   Handler signature: changeHandler( paramName, oldValue, newValue )
    def self.add_param( name, default, description, changeHandler = nil )
      self.logger.debug { "Adding parameter '#{name}' for plugin class '#{self.name}'" }
      if @@configFileData.kind_of?( Hash ) && @@configFileData.has_key?( @@config[self].plugin ) \
        && @@configFileData[@@config[self].plugin].has_key?( name )
        curval = @@configFileData[@@config[self].plugin][name]
      else
        curval = default
      end
      data = OpenStruct.new( :name => name, :value => curval, :default => default, :description => description, :changeHandler => changeHandler )
      (@@config[self].params ||= {})[name] = data
      changeHandler.call( name, default, curval ) if changeHandler
    end

    # Set parameter +name+ for +plugin+ to +value+.
    def self.set_param( plugin, name, value )
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

    def self.get_param( name )
      ancestor_classes.each do |klass|
        data = @@config[klass]
        return data.params[name].value unless data.params.nil? || data.params[name].nil?
      end
      logger.error { "Referencing invalid configuration value '#{name}' in class #{self.class.name}" }
      return nil
    end

    # Return parameter +name+.
    def []( name )
      self.class.get_param( name )
    end
    alias get_param []

    # Set parameter +name+.
    def []=( name, value )
      self.class.set_param( @@config[self.class].plugin, name, value )
    end

    # Checks if the plugin has a parameter +name+.
    def has_param?( name )
      self.class.ancestor_classes.any? do |klass|
        !@@config[klass].params.nil? && @@config[klass].params.has_key?( name )
      end
    end

    # Defines a new *handler class. The methods creates two methods based on the parameter +name+:
    # - klass.register_[name]
    # - object.get_[name]
    def self.define_handler( name )
      s = "def self.register_#{name}( param )
        self.logger.info { \"Registering class \#{self.name} for handling '\#{param}'\" }
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

    #######
    private
    #######

    # Return the ancestor classes for the object's class which are sub classes from Plugin.
    def self.ancestor_classes
      self.ancestors.delete_if {|c| c.instance_of?( Module ) }[0..-3]
    end

  end

  require 'webgen/logging'
  require 'webgen/configuration'

end


