#
# The main file containg the plugin registry and the base class for all plugins.
#
# $Id$
#

require 'singleton'
require 'find'
require 'util/listener'


module UPS

    class Registry

        include Singleton
        include Listener
        include Enumerable


        def Registry.method_missing( symbol, *args, &block )
            Registry.instance.send symbol, *args, &block
        end


        def initialize
            @plugins = Hash.new
            add_msg_name :PLUGIN_REGISTERED
            add_msg_name :PLUGIN_UNREGISTERED
        end


        def []( plugin )
            @plugins[plugin]
        end


        def register_plugin( pluginClass )
            name = pluginClass.const_get :NAME
            return false if @plugins.has_key? name
            @plugins[name] = pluginClass.new
            @plugins[name].init
            dispatch_msg :PLUGIN_REGISTERED, name
            return true
        end


        def unregister_plugin( pluginClass )
            name = pluginClass.const_get :NAME
            return false unless @plugins.has_key? name
            @plugins[name].destroy
            @plugins.delete name
            dispatch_msg :PLUGIN_UNREGISTERED, name
            return true
        end


        def load_plugins( path, trimpath )
            Find.find( path ) do |file|
                Find.prune unless File.directory?( file ) || (/.rb$/ =~ file)
                require file.gsub(/^#{trimpath}/, '') if File.file? file
            end
        end


        def each( &block )
            @plugins.each( &block )
        end

    end


    class Plugin

        def init
        end

        def destroy
        end

    end


end


if __FILE__ == $0

    class Test < UPS::Plugin
        NAME = "testPlugin"

        def init
            print "init"
        end

        def destroy
            print "destroy"
        end

    end

    UPS::Registry.add_msg_listener(:PLUGIN_REGISTERED) { |name| print "yes: #{name}" }
    UPS::Registry.register_plugin(Test)
    print UPS::Registry[Test::NAME]
    UPS::Registry.unregister_plugin(Test)
end
