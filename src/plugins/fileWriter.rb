require 'ups'
require 'configuration'
require 'thgexception'
require 'rexml/document'

class FileWriter < UPS::Controller
	
	def initialize
		super('fileWriter')
		config = Configuration.instance.pluginData['fileWriter']
		if config.nil?
			raise ThaumaturgeException.new('add entries for fileWriter'),
				'The configuration file has no section for fileWriter', caller
		end
		@outputDir = config.text('outputDir')
		@filenameGenerator = config.text('filenameGenerator')
	end

	def verify(plugin)
		plugin.respond_to?(:build_name)
	end

	def execute(tree)
		if !@plugins.has_key?(@filenameGenerator)
			raise ThaumaturgeException.new('select an exisiting filename generator'),
				'The chosen filename generator does not exist', caller
		end
		
		tree.each { |child|
			handleNode(child, tree)
		}
	end

	def handleNode(node, parent)
		print "#{node.title}\n"
		if node.children.length > 0
			node.each { |child|
				handleNode(child, node)
			}
		end
		if !node.virtual
			substituteTags(node.content.elements['content'], node)
			doc = REXML::Document.new(File.new(parent.templateFile))
			substituteTags(doc.root, node)
			filename = File.join(@outputDir, @plugins[@filenameGenerator].build_name(node.url))
			createDirs(filename)
			print "Writing #{filename}\n"
			File.open(filename, File::CREAT|File::TRUNC|File::RDWR) {|file|
				doc.write(file)
			}
		end
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

end	


class HierarchicFilename < UPS::StandardPlugin
	
	def initialize
		super('fileWriter', 'hierarchicFilename')
	end
	
	def build_name(name)
		File.join(File.dirname(name), File.basename(name, '.xml')) + '.html'
	end
	
end

UPS::PluginRegistry.instance.register_plugin(FileWriter.new)
UPS::PluginRegistry.instance.register_plugin(HierarchicFilename.new)
