require 'ups'

class TreeTransformer < UPS::Controller
	
	def initialize
		super('treeTransformer')
	end

	def verify(plugin)
		true
	end

	def execute(tree)
	end

end	

UPS::PluginRegistry.instance.register_plugin(TreeTransformer.new)
