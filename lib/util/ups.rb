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
# The main file containg the plugin registry and the base class for all plugins.
#

require 'singleton'
require 'find'
require 'util/listener'


module UPS

    # The plugin registry which manages plugins.
    class Registry

        include Singleton
        include Listener
        include Enumerable


        # Redirects all messages to the Singleton instance
        def Registry.method_missing( symbol, *args, &block )
            Registry.instance.send( symbol, *args, &block )
        end


        # Initializes the Singleton instance
        def initialize
            @plugins = Hash.new
            add_msg_name :PLUGIN_REGISTERED
            add_msg_name :PLUGIN_UNREGISTERED
        end


        # Retrieves the plugin with the given +name+
        def []( name )
            @plugins[name]
        end


        # Registers a new plugin. You have to supply the class of the plugin
        # which should have been derived from +UPS::Plugin+.
        def register_plugin( pluginClass )
            name = pluginClass.const_get :NAME
            return false if @plugins.has_key? name
            @plugins[name] = pluginClass.new
            @plugins[name].init
            dispatch_msg :PLUGIN_REGISTERED, name
            return true
        end


        # Unregisters the plugin with the given class.
        def unregister_plugin( pluginClass )
            name = pluginClass.const_get :NAME
            return false unless @plugins.has_key? name
            @plugins[name].destroy
            @plugins.delete name
            dispatch_msg :PLUGIN_UNREGISTERED, name
            return true
        end


        # Loads all plugins in the given +path+. Before +require+ is actually called the path is
        # trimmed: if +trimpath+ matches the beginning of the string, it is deleted from it.
        def load_plugins( path, trimpath )
            Find.find( path ) do |file|
                Find.prune unless File.directory?( file ) || (/.rb$/ =~ file)
                require file.gsub(/^#{trimpath}/, '') if File.file? file
            end
        end


        # Iterates over all registered plugins.
        def each( &block )
            @plugins.each( &block )
        end

    end


    # The default plugin class which implements the necessary default method stubs.
    class Plugin

        # Initializes the plugin. This method is called by +Registry#register_plugin+ after the
        # plugin was registered.
        def init
        end

        # Cleans up the plugin. This method is called by +Registry#unregister_plugin+ before the
        # plugin is deleted from the registry.
        def destroy
        end

    end


end
