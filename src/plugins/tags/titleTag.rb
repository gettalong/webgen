require 'ups/ups'
require 'plugins/tags/tags'

class TitleTag < UPS::Plugin

    NAME = "Title tag"
    SHORT_DESC = "Replaces the tag with the title of node"

    def init
        UPS::Registry['Tags'].tags['title'] = self
    end

	def process_tag( content, node, templateNode )
		node['title']
	end

end

UPS::Registry.register_plugin TitleTag
