require 'ups'

class ContentTag < UPS::StandardPlugin
	
	def initialize
		super('tags', 'content')
	end

	def describe
		"Replaces <content> with the actual content of the current file"
	end

	def execute(content, node)
		node.metainfo['content']
	end

end

UPS::PluginRegistry.instance.register_plugin(ContentTag.new)
