require 'rexml/document'
require 'configuration'
require 'tree'

class Parser

	def initialize
	end

	def build_tree
		return handleEntry(Configuration.instance.srcDirectory, '', nil)
	end

	def handleEntry(absName, relName, parent)
		print "Processing #{absName}\n"
		if FileTest.file?(absName) # handle file
			root = REXML::Document.new(File.new(absName)).root
			
			# initialize attributes
			title = root.text('/thg/metainfo/title')
			raise "title entry not found" if title.nil? 
			node = Node.new(title, relName, false)
			node.content = root
		elsif FileTest.directory?(absName) # recursively load files
			node = DirectoryNode.new(relName, relName, (parent.nil? ? '' : parent.templateFile))
			Dir[File.join(absName, '*')].each { |filename|
				next if !(/\.xml$/ =~ filename) && !FileTest.directory?(filename)
				name = (parent.nil? ? '' : relName + '/') + File.basename(filename)
				node.add_child(handleEntry(filename, name, node))
			}
		end
		return node
	end

end
