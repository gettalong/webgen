require 'ups'
require 'configuration'

class TreeTransformer < UPS::Controller
	
	def initialize
		super('treeTransformer')
	end

	def verify(plugin)
		true
	end

	def describe
		"Provides standard methods for plugins which transform the data tree."
	end

	def execute(tree, level = 0)
		@plugins.each_value {|plugin|
			plugin.execute(tree)
		}
	end

end	


class DebugTreePrinter < UPS::StandardPlugin

	def initialize
		super('treeTransformer', 'debugTreePrinter')
	end

	def describe
		"Prints out the information in the tree for debug purposes."
	end

	def execute(node, level = 0)
		# just print all the nodes
		Configuration.instance.log(2, "".ljust(level*4) << "#{node.title}: #{node.src} -> #{node.url}")
		if node.children.length > 0
			node.each { |child|
				execute(child, level + 1)
			}
		end
	end

end

UPS::PluginRegistry.instance.register_plugin(TreeTransformer.new)
UPS::PluginRegistry.instance.register_plugin(DebugTreePrinter.new) if Configuration.instance.verbosityLevel >= 2
