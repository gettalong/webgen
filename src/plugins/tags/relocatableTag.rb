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
		#TODO make it really relocatable instead of printing the inner element
		result = ''
		REXML::Document.new(content).root.elements[1].write(result)
		result
	end

end

UPS::PluginRegistry.instance.register_plugin(RelocatableTag.new)
