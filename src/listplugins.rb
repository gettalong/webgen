require 'ups/ups'

class ThgListPlugin < UPS::Plugin

    NAME = "List Plugins"
    SHORT_DESC = "Pretty prints the plugin descriptions"

	def list_plugins
        UPS::Registry.each do |name, plugin|
            print "  * #{name}:".ljust(30) +"#{plugin.class.const_get :SHORT_DESC}\n"
        end
	end

end

UPS::Registry.register_plugin( ThgListPlugin )
