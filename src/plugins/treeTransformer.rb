require 'ups'

class TreeTransformer < UPS::Controller
	
	def initialize
		super('treeTransformer')
	end

	def verify(plugin)
		true
	end

	def execute(node, level = 0)
		# just print all the nodes
		Configuration.instance.log(2, "".ljust(level*4) << "#{node.title}: #{node.srcName} -> #{node.url}")
		if node.children.length > 0
			node.each { |child|
				execute(child, level + 1)
			}
		end
	end

end	

UPS::PluginRegistry.instance.register_plugin(TreeTransformer.new)
