require 'ups'

class RelocatableTag < UPS::StandardPlugin
	
	def initialize
		super('tags', 'relocatable')
	end

	def describe
		"Replaces the href attribute of the surrounded element with the correct " <<
			"relative reference"
	end

	def execute(content, node)
		
	end

end

UPS::PluginRegistry.instance.register_plugin(RelocatableTag.new)
