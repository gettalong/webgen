require 'ups/ups'
require 'plugins/tags/tags'

class MetaTag < UPS::Plugin

    NAME = "Meta tag"
    SHORT_DESC = "Replaces all tags without tag plugin with their respective values from the node meta data"

    def init
        UPS::Registry['Tags'].tags[:default] = self
    end

	def process_tag( tag, content, node, templateNode )
		node[tag] || ''
	end

end

UPS::Registry.register_plugin MetaTag
