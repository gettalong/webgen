require 'ups'
require 'thgexception'

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
		content.gsub!(/<thg:(\w+)\s*?.*?(\/>|>.*?<\/thg:\1>)/) { |match|
			Configuration.instance.debug("Replacing tag: #{$1}, match: #{match}")
			raise ThgException.new(ThgException::TAGS_UNKNOWN_TAG, $1) if !@plugins.has_key?($1)
			@plugins[$1].execute(match, node)
		}
	end

end


UPS::PluginRegistry.instance.register_plugin(Tags.new)
