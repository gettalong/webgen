require 'fileutils'
require 'rexml/document'
require 'ups'
require 'configuration'
require 'thgexception'
require 'listener'
require 'node'

class FileHandler < UPS::Controller
	
	include Listener

	attr_accessor :extensions
	attr_accessor :outputDir

	def initialize
		super('fileHandler')
		@extensions = Hash.new

		config = Configuration.instance.pluginData['fileHandler']
		raise ThgException.new(ThgException::CFG_ENTRY_NOT_FOUND, 'fileHandler') if config.nil?

		add_msg_name(:DIR_NODE_CREATED)
	end

	def describe
		"Provides interface on file level. The FileHandler goes through the source " +
			"directory, reads in all files for which approriate plugins exist and " +
			"builds the tree. When all approriate transformations on the tree have " +
			"been performed the FileHandler is used to write the output files."
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

	def write_tree(tree)
		write_node(tree)
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

	def write_node(node)
		name = File.join(@outputDir, node.abs_url)
		Configuration.instance.log(1, "Writing #{name}")

		node.processor.write_node(node, name)

		if node.children.length > 0
			node.each { |child|
				write_node(child)
			}
		end
	end

end	

class XMLPagePlugin < UPS::StandardPlugin
	
	ThgException.add_entry :PAGE_META_ENTRY_NOT_FOUND,
		"the tag <%0> has not be found in the <meta> section of the page file %1",
		"<%0> is not optional, you have to add it to the page file"

	ThgException.add_entry :PAGE_DIR_INDEX_FILE_NOT_FOUND,
		"directory index file does not exist for %0",
		"create an %1 in that directory"
	
	ThgException.add_entry :PAGE_TEMPLATE_FILE_NOT_FOUND,
		"template file in root directory not found",
		"create an %0 in the root directory"

	attr_reader :templateFile
	attr_reader :directoryIndexFile

	def initialize
		super('fileHandler', 'xmlPagePlugin')
	end	

	def after_register
		UPS::PluginRegistry.instance['fileHandler'].extensions['xml'] = self
		UPS::PluginRegistry.instance['fileHandler'].add_msg_listener(FileHandler::DIR_NODE_CREATED, method(:add_template_to_node))
	end

	def describe
		"Implements the handling of xml page files. These are the files that are transformed into " <<
			"XHTML files."
	end

	def add_template_to_node(node)
		cfg = Configuration.instance
		
		if !File.exists?(node.abs_src + cfg.directoryIndexFile)
			raise ThgException.new(ThgException::PAGE_DIR_INDEX_FILE_NOT_FOUND,
								   (dir == '' ? 'root directory' : dir), cfg.directoryIndexFile)
		end

		node.metainfo['templateFile'] = node.abs_src + cfg.templateFile
		if !File.exists?(node.metainfo['templateFile'])
			if node.parent.nil? # dir is root directory
				raise ThgException.new(ThgException::PAGE_TEMPLATE_FILE_NOT_FOUND, cfg.templateFile)
			end
			node.metainfo['templateFile'] = node.parent.metainfo['templateFile']
		end
	end

	def build_node(srcName, parent)
		root = REXML::Document.new(File.new(srcName)).root
			
		# initialize attributes
		title = root.text('/thg/metainfo/title')
		raise ThgException.new(ThgException::PAGE_META_ENTRY_NOT_FOUND, 'title', srcName) if title.nil? 
		
		urlName = File.basename(srcName.gsub(/\.xml$/, '.html'))

		node = Node.new(parent, title, urlName, File.basename(srcName))
		node.content = ''
		root.elements['content'].each { |child| child.write(node.content) }

		return node
	end

	def write_node(node, filename)
		doc = ''
		File.open(node.parent.metainfo['templateFile']) { |file|
			doc = file.read
		}

		UPS::PluginRegistry.instance['tags'].substituteTags(node.content, node)
		UPS::PluginRegistry.instance['tags'].substituteTags(doc, node)

		File.open(filename, File::CREAT|File::TRUNC|File::RDWR) {|file|
			file.write(doc)
		}
	end

end

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

UPS::PluginRegistry.instance.register_plugin(FileHandler.new, true)
UPS::PluginRegistry.instance.register_plugin(XMLPagePlugin.new, true)
UPS::PluginRegistry.instance.register_plugin(FileCopyPlugin.new)
