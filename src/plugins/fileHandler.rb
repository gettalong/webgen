require 'ups'
require 'configuration'
require 'thgexception'
require 'rexml/document'
require 'fileutils'

class FileHandler < UPS::Controller
	
	attr_accessor :extensions

	def initialize
		super('fileHandler')
		@extensions = Hash.new

		config = Configuration.instance.pluginData['fileHandler']
		raise ThgException.new(ThgException::CFG_ENTRY_NOT_FOUND, 'fileHandler') if config.nil?

		@outputDir = config.text('outputDir')
		raise ThgException.new(ThgException::CFG_ENTRY_NOT_FOUND, 'fileHandler/outputDir') if @outputDir.nil?
	end

	def describe
		"Provides interface on file level. The FileHandler goes through the source " +
			"directory, reads in all files for which approriate plugins exist and " +
			"builds the tree. When all approriate transformations on the tree have " +
			"been performed the FileHandler is used to write the output files."
	end

	def write_tree(tree)
		tree.each { |child|
			write_node(child, tree)
		}
	end

	def build_tree
		build_entry(Configuration.instance.srcDirectory, '', nil)
	end


	#######
	private
	#######

	def write_node(node, parent)
		if !node.virtual
			filename = File.join(@outputDir, node.url)
			Configuration.instance.log(1, "Writing #{filename}")
			
			extension = node.srcName[/\.(.*)$/][1..-1]
			@extensions[extension].write_node(node, parent, filename)
		end
		if node.children.length > 0
			node.each { |child|
				write_node(child, node)
			}
		end
	end

	def build_entry(absName, relName, parent)
		Configuration.instance.log(1, "Processing #{absName}")

		if FileTest.file?(absName)
			extension = absName[/\..*$/][1..-1]

			if !@extensions.has_key?(extension)
				Configuration.instance.log(1, "  no plugin for file -> ignored")
				node = nil;
			else
				node = @extensions[extension].build_node(absName, relName)
			end
		elsif FileTest.directory?(absName)
			node = DirectoryNode.new("Directory #{relName}", relName, (parent.nil? ? '' : parent.templateFile))

			Dir[File.join(absName, '*')].each { |filename|
				name = (parent.nil? ? '' : relName) + File.basename(filename)
				name << '/' if FileTest.directory? filename
				child = build_entry(filename, name, node)
				node.add_child(child) if !child.nil?
			}
		end

		return node
	end


end	

class XMLPagePlugin < UPS::StandardPlugin
	
	ThgException.add_entry :PAGE_META_ENTRY_NOT_FOUND,
		"the tag <%0> has not be found in the <meta> section of the page file %1",
		"<%0> is not optional, you have to add it to the page file"

	def initialize
		super('fileHandler', 'xmlPagePlugin')
	end	

	def after_register
		UPS::PluginRegistry.instance['fileHandler'].extensions['xml'] = self
	end

	def describe
		"Implements the handling of xml page files. These are the files that are transformed into " <<
			"XHTML files."
	end

	def build_node(absName, relName)
		root = REXML::Document.new(File.new(absName)).root
			
		# initialize attributes
		title = root.text('/thg/metainfo/title')
		raise ThgException.new(ThgException::PAGE_META_ENTRY_NOT_FOUND, 'title', absName) if title.nil? 
		
		urlName = relName.gsub(/\.xml$/, '.html')

		node = Node.new(title, urlName, relName, false)
		node.content = ''
		root.elements['content'].each { |child| child.write(node.content) }

		return node
	end

	def write_node(node, parent, filename)
		doc = ''
		File.open(parent.templateFile) { |file|
			doc = file.read
		}

		UPS::PluginRegistry.instance['tags'].substituteTags(node.content, node)
		UPS::PluginRegistry.instance['tags'].substituteTags(doc, node)
		FileUtils.makedirs(File.dirname(filename))

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

	def build_node(absName, relName)
		Node.new('<File>', relName, relName, false)
	end

	def write_node(node, parent, filename)
		srcFile = File.join(Configuration.instance.srcDirectory, node.srcName)
		FileUtils.cp(srcFile, filename)
	end

end

UPS::PluginRegistry.instance.register_plugin(FileHandler.new)
UPS::PluginRegistry.instance.register_plugin(XMLPagePlugin.new)
UPS::PluginRegistry.instance.register_plugin(FileCopyPlugin.new)
