require 'ups'
require 'thgexception'
require 'node'

class XMLPagePlugin < UPS::StandardPlugin
	
	ThgException.add_entry :PAGE_META_ENTRY_NOT_FOUND,
		"the tag <%0> has not be found in the <meta> section of the page file %1",
		"<%0> is not optional, you have to add it to the page file"

	ThgException.add_entry :PAGE_TEMPLATE_FILE_NOT_FOUND,
		"template file in root directory not found",
		"create an %0 in the root directory"


	attr_reader :templateFile
	attr_reader :directoryIndexFile

	EXTENSION = 'page'

	def initialize
		super('fileHandler', 'xmlPagePlugin')

		config = Configuration.instance.pluginData['xmlPagePlugin']
		raise ThgException.new(ThgException::CFG_ENTRY_NOT_FOUND, 'xmlPagePlugin') if config.nil?

		@templateFile = config.text('templateFile')
		@directoryIndexFile = config.text('directoryIndexFile')
	end	


	def after_register
		UPS::PluginRegistry.instance['fileHandler'].extensions[EXTENSION] = self
		UPS::PluginRegistry.instance['fileHandler'].add_msg_listener(FileHandler::AFTER_DIR_READ, method(:add_template_to_node))
	end


	def describe
		"Implements the handling of xml page files. These are the files that are transformed into " <<
			"XHTML files."
	end


	def build_node(srcName, parent)
		root = REXML::Document.new(File.new(srcName)).root
			
		# initialize attributes
		title = root.text('/thg/metainfo/title')
		raise ThgException.new(ThgException::PAGE_META_ENTRY_NOT_FOUND, 'title', srcName) if title.nil? 
		
		urlName = File.basename(srcName.gsub(/\.#{EXTENSION}$/, '.html'))

		node = Node.new(parent, title, urlName, File.basename(srcName))
		node.metainfo['content'] = ''
		root.elements['content'].each { |child| child.write(node.metainfo['content']) }

		return node
	end


	def write_node(node, filename)
		template = get_template_for_node(node).metainfo['content'].dup

		UPS::PluginRegistry.instance['tags'].substituteTags(node.metainfo['content'], node)
		UPS::PluginRegistry.instance['tags'].substituteTags(template, node)

		File.open(filename, File::CREAT|File::TRUNC|File::RDWR) {|file|
			file.write(template)
		}
	end

	#######
	private
	#######

	def add_template_to_node(node)
		cfg = Configuration.instance		
		
		if node.find { |child| child.src == @directoryIndexFile}.nil?
			Configuration.instance.warning("directory index file for #{node.abs_src} not found")
		end

		templateNode = node.find { |child| child.src == @templateFile }
		if !templateNode.nil? 
			node.metainfo['templateFile'] = templateNode
		elsif node.parent.nil? # dir is root directory
			raise ThgException.new(ThgException::PAGE_TEMPLATE_FILE_NOT_FOUND, @templateFile)
		end
	end


	def get_template_for_node(node)
		if node.nil?
			raise "Template file for node not found -> this should not happen!"
		end
		if node.metainfo.has_key? 'templateFile'
			return node.metainfo['templateFile']
		else
			return get_template_for_node(node.parent)
		end
	end

end

UPS::PluginRegistry.instance.register_plugin(XMLPagePlugin.new)

