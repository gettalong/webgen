require 'ups'
require 'thgexception'
require 'node'

class TemplatePlugin < UPS::StandardPlugin

	EXTENSION = 'template'

	def initialize
		super('fileHandler', 'templatePlugin')
	end

	def after_register
		UPS::PluginRegistry.instance['fileHandler'].extensions[EXTENSION] = self
	end

	def describe
		"Represents the template files for the page generation in the tree."
	end

	def build_node(srcName, parent)
		urlName = File.basename(srcName)
		node = Node.new(parent, 'Template', urlName)
		File.open(srcName) { |file|
			node.metainfo['content'] = file.read
		}
		return node
	end

	def write_node(node, filename)
		# do not write anything
	end

end

UPS::PluginRegistry.instance.register_plugin(TemplatePlugin.new)
