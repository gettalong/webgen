require 'ups/ups'

class ThgListPlugin < UPS::Plugin

    NAME = "List Plugins"
    SHORT_DESC = "Pretty prints the plugin descriptions"

	def list
        UPS::Registry.sort.each do |entry|
            print "  * #{entry[0]}:".ljust(30) +"#{entry[1].class.const_get :SHORT_DESC}\n"
        end
	end

end


class ThgListConfiguration < UPS::Plugin

    NAME = "List Configuration"
    SHORT_DESC = "Pretty prints the plugin configuration parameters"

	def list
        params = UPS::Registry['Configuration'].configParams
        params.sort.each do |entry|
            print "  * #{entry[0]}\n"
            entry[1].each do |paramValue|
                print "      #{paramValue[0]}:".ljust(30) +"#{paramValue[1].inspect} | #{paramValue[2].inspect}\n"
            end
        end
	end

end


UPS::Registry.register_plugin( ThgListPlugin )
UPS::Registry.register_plugin( ThgListConfiguration )
