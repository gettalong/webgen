require 'ups'

class Tags < UPS::Controller

	def initialize
		super('tags')
	end

	def verify(plugin)
		plugin.respond_to?(:execute)
	end

	def describe
		"Provides standard methods for tag plugins"
	end

	def substituteTags(content, node)
		content.gsub!(/<thg:(\w+)\s*?.*?(\/>|<\/\1>)/) { |match|
			if !@plugins.has_key?($1)
				raise ThgException.new('remove the invalid thg tag'),
					"thg tag found for which no plugin exists (#{$1})", caller
			end
			
			@plugins[$1].execute(match, node)
		}
	end

end


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

class ContentTag < UPS::StandardPlugin
	
	def initialize
		super('tags', 'content')
	end

	def describe
		"Replaces <content> with the actual content of the current file"
	end

	def execute(content, node)
		node.content
	end

end

UPS::PluginRegistry.instance.register_plugin(Tags.new)
UPS::PluginRegistry.instance.register_plugin(TitleTag.new)
UPS::PluginRegistry.instance.register_plugin(ContentTag.new)
