require 'ups'
require 'configuration'
require 'thgexception'
require 'rexml/document'

class FileHandler < UPS::Controller
	
	def initialize
		super('fileHandler')

		config = Configuration.instance.pluginData['fileHandler']
		if config.nil?
			raise ThaumaturgeException.new('add entries for fileWriter'),
				'The configuration file has no section for fileWriter', caller
		end

		@outputDir = config.text('outputDir')
		@filenameGenerator = config.text('filenameGenerator')
	end

	def write_tree(tree)
		if !@plugins.has_key?(@filenameGenerator)
			raise ThaumaturgeException.new('select an exisiting filename generator'),
				'The chosen filename generator does not exist', caller
		end
		
		tree.each { |child|
			write_node(child, tree)
		}
	end

	def build_tree
		return build_entry(Configuration.instance.srcDirectory, '', nil)
	end

	def createDirs(filename)
		dir = File.dirname(filename)
		rootdir = ''
		dir.split('/').each {|subdir|
			rootdir = rootdir + subdir + File::SEPARATOR
			begin
				Dir.mkdir(rootdir)
			rescue
			end
		}
	end

	def substituteTags(root, node)
		plugins = UPS::PluginRegistry.instance['tags'].plugins
		root.each_element("//*") { |element|
			next if !(/^thg$/ =~ element.namespace)
			if !plugins.has_key?(element.name)
				raise ThaumaturgeException.new('remove the invalid thg tag'),
					"thg tag found for which no plugin exists (#{element.name})", caller
			end
			plugins[element.name].execute(element, node)
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
			filename = File.join(@outputDir, @plugins[@filenameGenerator].build_name(node.url))
			extension = 'ext_' + node.srcName[/\.(.*)$/][1..-1]
			@plugins[extension].write_node(node, parent, filename)
		end
	end

	def build_entry(absName, relName, parent)
		print "Processing #{absName}\n"

		if FileTest.file?(absName)
			extension = 'ext_' + absName[/\..*$/][1..-1]

			if !@plugins.has_key?(extension)
				if !@plugins.has_key?('otherExtensions')
					raise ThaumaturgeException.new('add a new plugin for this file type'),
						"file extension found for which no plugin exists (#{extension[4..-1]})", caller
				end
				extension = 'otherExtensions'
			end
			node = @plugins[extension].build_node(absName, relName)
		elsif FileTest.directory?(absName)
			node = DirectoryNode.new(relName, relName, (parent.nil? ? '' : parent.templateFile))

			Dir[File.join(absName, '*')].each { |filename|
				name = (parent.nil? ? '' : relName + '/') + File.basename(filename)
				child = build_entry(filename, name, node)
				node.add_child(child) if !child.nil?
			}
		end
		return node
	end


end	

class OtherExtensionsPlugin < UPS::StandardPlugin
	
	def initialize
		super('fileHandler', 'otherExtensions')
	end

	def build_node(absName, relName)
		nil
	end
	
end

class XMLPagePlugin < UPS::StandardPlugin
	
	def initialize
		super('fileHandler', 'ext_xml')
	end

	def build_node(absName, relName)
		root = REXML::Document.new(File.new(absName)).root
			
		# initialize attributes
		title = root.text('/thg/metainfo/title')
		raise "title entry not found" if title.nil? 
		
		urlName = relName.gsub(/\.xml$/, '.html')

		node = Node.new(title, urlName, relName, false)
		node.content = root

		return node
	end

	def write_node(node, parent, filename)
		doc = REXML::Document.new(File.new(parent.templateFile))

		UPS::PluginRegistry.instance['fileHandler'].substituteTags(node.content.elements['content'], node)
		UPS::PluginRegistry.instance['fileHandler'].substituteTags(doc.root, node)
		UPS::PluginRegistry.instance['fileHandler'].createDirs(filename)

		print "Writing #{filename}\n"
		File.open(filename, File::CREAT|File::TRUNC|File::RDWR) {|file|
			doc.write(file)
		}
	end
	
end

class HierarchicFilenameGenerator < UPS::StandardPlugin
	
	def initialize
		super('fileHandler', 'hierarchicFilenameGenerator')
	end
	
	def build_name(name)
		name
	end
	
end

UPS::PluginRegistry.instance.register_plugin(FileHandler.new)

UPS::PluginRegistry.instance.register_plugin(OtherExtensionsPlugin.new)
UPS::PluginRegistry.instance.register_plugin(XMLPagePlugin.new)

UPS::PluginRegistry.instance.register_plugin(HierarchicFilenameGenerator.new)
