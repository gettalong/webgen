require 'ups'

class TitleTag < UPS::StandardPlugin
	
	def initialize
		super('tags', 'title')
	end

	def describe
		"Replaces <title> tag with title of node"
	end

	def execute(content, node)
		node.title
	end

end

UPS::PluginRegistry.instance.register_plugin(TitleTag.new)
