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
		if config.nil?
			raise ThaumaturgeException.new('add entries for fileWriter'),
				'The configuration file has no section for fileWriter', caller
		end

		@outputDir = config.text('outputDir')
	end

	def write_tree(tree)
		tree.each { |child|
			write_node(child, tree)
		}
	end

	def build_tree
		build_entry(Configuration.instance.srcDirectory, '', nil)
	end


	def substituteTags(content, node)
		plugins = UPS::PluginRegistry.instance['tags'].plugins
		content.gsub!(/<thg:(\w+)\s*?.*?(\/>|<\/\1>)/) { |match|
			if !plugins.has_key?($1)
				raise ThaumaturgeException.new('remove the invalid thg tag'),
					"thg tag found for which no plugin exists (#{$1})", caller
			end
			
			plugins[$1].execute(match, node)
		}
	end

	#######
	private
	#######

	def write_node(node, parent)
		if node.children.length > 0
			node.each { |child|
				write_node(child, node)
			}
		end
		if !node.virtual
			filename = File.join(@outputDir, node.url)
			print "Writing #{filename}\n"
			
			extension = node.srcName[/\.(.*)$/][1..-1]
			@extensions[extension].write_node(node, parent, filename)
		end
	end

	def build_entry(absName, relName, parent)
		print "Processing #{absName}"

		if FileTest.file?(absName)
			extension = absName[/\..*$/][1..-1]

			if !@extensions.has_key?(extension)
				print " -> ignored\n"
				node = nil;
			else
				print "\n"
				node = @extensions[extension].build_node(absName, relName)
			end
		elsif FileTest.directory?(absName)
			print "\n"
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
	
	def initialize
		super('fileHandler', 'xmlPagePlugin')
	end

	def after_register
		UPS::PluginRegistry.instance['fileHandler'].extensions['xml'] = self
	end

	def build_node(absName, relName)
		root = REXML::Document.new(File.new(absName)).root
			
		# initialize attributes
		title = root.text('/thg/metainfo/title')
		raise "title entry not found" if title.nil? 
		
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

		UPS::PluginRegistry.instance['fileHandler'].substituteTags(node.content, node)
		UPS::PluginRegistry.instance['fileHandler'].substituteTags(doc, node)
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
