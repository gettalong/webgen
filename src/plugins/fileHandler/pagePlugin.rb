require 'ups'
require 'thgexception'
require 'node'

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
		UPS::PluginRegistry.instance['fileHandler'].add_msg_listener(FileHandler::DIR_NODE_CREATED, method(:add_template_to_node))
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
		
		urlName = File.basename(srcName.gsub(/\.EXTENSION$/, '.html'))

		node = Node.new(parent, title, urlName, File.basename(srcName))
		node.metainfo['content'] = ''
		root.elements['content'].each { |child| child.write(node.metainfo['content']) }

		return node
	end


	def write_node(node, filename)
		doc = ''
		File.open(node.parent.metainfo['templateFile']) { |file|
			doc = file.read
		}

		UPS::PluginRegistry.instance['tags'].substituteTags(node.metainfo['content'], node)
		UPS::PluginRegistry.instance['tags'].substituteTags(doc, node)

		File.open(filename, File::CREAT|File::TRUNC|File::RDWR) {|file|
			file.write(doc)
		}
	end

	#######
	private
	#######

	def add_template_to_node(node)
		cfg = Configuration.instance
		
		if !File.exists?(node.abs_src + @directoryIndexFile)
			raise ThgException.new(ThgException::PAGE_DIR_INDEX_FILE_NOT_FOUND,
								   (node.parent.nil? ? 'root directory' : node.abs_src), @directoryIndexFile)
		end

		node.metainfo['templateFile'] = node.abs_src + @templateFile
		if !File.exists?(node.metainfo['templateFile'])
			if node.parent.nil? # dir is root directory
				raise ThgException.new(ThgException::PAGE_TEMPLATE_FILE_NOT_FOUND, @templateFile)
			end
			node.metainfo['templateFile'] = node.parent.metainfo['templateFile']
		end
	end


end

UPS::PluginRegistry.instance.register_plugin(XMLPagePlugin.new)

