require 'ups/ups'
require 'plugins/tags/tags'

class MetaTag < UPS::Plugin

    NAME = "Meta tag"
    SHORT_DESC = "Replaces user defined tags with their respective values from the node meta data"

    def init
        tags = UPS::Registry['Configuration'].get_config_value( NAME, 'tags' ) || ['title', 'content']
        tags.each do |tag|
            UPS::Registry['Tags'].tags[tag] = self
        end
    end

	def process_tag( tag, content, node, templateNode )
		node[tag]
	end

end

UPS::Registry.register_plugin MetaTag
