require 'ups/ups'
require 'plugins/tags/tags'

class RelocatableTag < UPS::Plugin

    NAME = 'Relocatable Tag'
    SHORT_DESC = 'Adds a relative path to the specified name if necessary'

    def init
        UPS::Registry['Tags'].tags['relocatable'] = self
    end

	def process_tag( path, node )
		#TODO make it really relocatable instead of printing the inner element
        path
	end

end

UPS::Registry.register_plugin RelocatableTag
