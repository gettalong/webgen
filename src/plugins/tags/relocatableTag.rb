require 'ups/ups'
require 'plugins/tags/tags'

class RelocatableTag < UPS::Plugin

    NAME = 'Relocatable Tag'
    SHORT_DESC = 'Adds a relative path to the specified name if necessary'

    def init
        UPS::Registry['Tags'].tags['relocatable'] = self
    end

	def process_tag( tag, content, node, templateNode )
        UPS::Registry['Tree Utils'].get_relpath_to_node( node, templateNode ) + content
	end

end

UPS::Registry.register_plugin RelocatableTag
