require 'ups/ups'
require 'thgexception'
require 'node'
require 'plugins/fileHandler/fileHandler'

class TemplatePlugin < UPS::Plugin

    NAME = "Template File"
    SHORT_DESC = "Represents the template files for the page generation in the tree"

	EXTENSION = 'template'

	def init
		UPS::Registry['File Handler'].extensions[EXTENSION] = self
	end

	def create_node( srcName, parent )
		relName = File.basename srcName
		node = Node.new parent
        node['title'] = 'Template'
        node['src'] = node['dest'] = relName
		File.open( srcName ) do |file|
			node['content'] = file.read
		end
		return node
	end

	def write_node(node, filename)
		# do not write anything
	end

end

UPS::Registry.register_plugin TemplatePlugin
