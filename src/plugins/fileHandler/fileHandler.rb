require 'ups'
require 'configuration'
require 'thgexception'
require 'listener'
require 'node'

class FileHandler < UPS::Controller
	
	include Listener

	attr_accessor :extensions

	def initialize
		super('fileHandler')
		@extensions = Hash.new

		#config = Configuration.instance.pluginData['fileHandler']
		#raise ThgException.new(ThgException::CFG_ENTRY_NOT_FOUND, 'fileHandler') if config.nil?

		add_msg_name(:DIR_NODE_CREATED)
	end

	def describe
		s = "Provides interface on file level. The FileHandler goes through the source " +
			"directory, reads in all files for which approriate plugins exist and " +
			"builds the tree. When all approriate transformations on the tree have " +
			"been performed the FileHandler is used to write the output files."
		@extensions.each {|ext, plugin|
			s += "\n#{ext} -> #{plugin.class}"
		}
		s
	end

	def build_tree
		@dirProcessor = Object.new
		def @dirProcessor.write_node(node, filename)
			FileUtils.makedirs(filename) if !File.exists?(filename)
		end

		root = build_entry(Configuration.instance.srcDirectory, nil)
		root.url = ""
		root.title = '/'
		root.src = Configuration.instance.srcDirectory + File::SEPARATOR
		root
	end

	def write_tree(node)
		name = File.join(Configuration.instance.outDirectory, node.abs_url)
		Configuration.instance.log(1, "Writing #{name}")

		node.processor.write_node(node, name)

		if node.children.length > 0
			node.each { |child|
				write_tree(child)
			}
		end
	end

	#######
	private
	#######

	def build_entry(srcName, parent)
		Configuration.instance.log(1, "Processing #{srcName}")

		if FileTest.file?(srcName)
			extension = srcName[/\..*$/][1..-1]

			if !@extensions.has_key?(extension)
				Configuration.instance.log(1, "  no plugin for file -> ignored")
				node = nil;
			else
				node = @extensions[extension].build_node(srcName, parent)
				node.processor = @extensions[extension]
			end
		elsif FileTest.directory?(srcName)
			relName = File.basename(srcName)
			node = Node.new(parent, relName, relName + File::SEPARATOR)
			node.processor = @dirProcessor

			dispatch_msg(DIR_NODE_CREATED, node)

			Dir[File.join(srcName, '*')].each { |filename|
				child = build_entry(filename, node)
				node.add_child(child) if !child.nil?
			}
		end

		return node
	end

end	

UPS::PluginRegistry.instance.register_plugin(FileHandler.new)
