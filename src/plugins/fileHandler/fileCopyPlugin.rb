require 'fileutils'
require 'ups'
require 'thgexception'
require 'node'

class FileCopyPlugin < UPS::StandardPlugin

	def initialize
		super('fileHandler', 'fileCopyPlugin')
	end

	def after_register
		types = Configuration.instance.pluginData['fileCopy'].text
		
		if !types.nil?
			types.split(',').each {|type|
				UPS::PluginRegistry.instance['fileHandler'].extensions[type] = self
			}
		end
	end

	def describe
		"Implements a generic file copy plugin. All the file types which are specified in the " <<
			"configuration file are copied without any transformation into the destination directory."
	end

	def build_node(srcName, parent)
		relName = File.basename(srcName)
		Node.new(parent, relName, relName)
	end

	def write_node(node, filename)
		FileUtils.cp(node.abs_src, filename)
	end

end

UPS::PluginRegistry.instance.register_plugin(FileCopyPlugin.new)
