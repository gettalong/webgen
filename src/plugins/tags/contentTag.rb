require 'ups/ups'
require 'plugins/tags/tags'

class ContentTag < UPS::Plugin

    NAME = "Content Tag"
    SHORT_DESC = "Replaces the tag with the actual content"

	def init
        UPS::Registry['Tags'].tags['content'] = self
	end


	def process_tag( content, node )
		node['content']
	end

end

UPS::Registry.register_plugin ContentTag
