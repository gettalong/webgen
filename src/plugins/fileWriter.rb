require 'ups'

class FileWriter < UPS::Controller
	
	def initialize
		super('fileWriter')
	end

	def verify(plugin)
		true
	end

	def execute(tree)
	end

end	

UPS::PluginRegistry.instance.register_plugin(FileWriter.new)
