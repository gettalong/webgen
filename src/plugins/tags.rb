require 'ups'

class Tags < UPS::Controller

	def initialize
		super('tags')
	end

	def describe
		"Provides standard methods for tag plugins"
	end

end


class TitleTag < UPS::StandardPlugin
	
	def initialize
		super('tags', 'title')
	end

	def execute(content, node)
		node.title
	end

	def describe
		"Replaces <title> tag with title of node"
	end

end

class ContentTag < UPS::StandardPlugin
	
	def initialize
		super('tags', 'content')
	end

	def execute(content, node)
		node.content
	end

	def describe
		"Replaces <content> with the actual content of the file"
	end

end

UPS::PluginRegistry.instance.register_plugin(Tags.new)
UPS::PluginRegistry.instance.register_plugin(TitleTag.new)
UPS::PluginRegistry.instance.register_plugin(ContentTag.new)
