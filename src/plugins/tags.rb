require 'ups'

class Tags < UPS::Controller

	ThgException.add_entry :TAGS_UNKNOWN_TAG,
		"found tag <thg:%0> for which no plugin exists",
		"either remove the tag or implement a plugin for it"

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
			raise ThgException.new(ThgException::TAGS_UNKNOWN_TAG, $1) if !@plugins.has_key?($1)
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
