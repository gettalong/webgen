require 'ups/ups'
require 'plugins/tags/tags'

class RelocatableTag < UPS::Plugin

    NAME = 'Relocatable Tag'
    SHORT_DESC = 'Adds a relative path to the specified name if necessary'

    def init
        UPS::Registry['Tags'].tags['relocatable'] = self
    end

	def process_tag( tag, content, node, refNode )
        destNode = refNode.get_node_for_string( content )
        node.get_relpath_to_node( destNode ) + destNode['dest'] unless destNode.nil?
	end

end

UPS::Registry.register_plugin RelocatableTag
