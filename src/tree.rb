require 'composite'

class Node
	
	include Composite

	attr_reader   :parent
	attr_accessor :title
	attr_accessor :url
	attr_accessor :src

	attr_accessor :content
	attr_reader   :metainfo
	attr_accessor :processor
	
	def initialize(parent, title, url, src = url)
		init_composite

		@parent = parent
		@title = title
		@url = url
		@src = src

		@metainfo = Hash.new
	end

	def abs_src
		if parent.nil?
			src
		else
			parent.abs_src + src
		end
	end

	def abs_url
		if parent.nil?
			url
		else
			parent.abs_url + url
		end
	end

end

=begin
class DirectoryNode < Node
	
	attr_reader :templateFile

	def initialize(title, dir, parentTemplateFile)
		cfg = Configuration.instance

		if !File.exists?(File.join(cfg.srcDirectory, dir, cfg.directoryIndexFile))
			raise ThgException.new("create an #{cfg.directoryIndexFile} in that directory"), 
				"directory index file does not exist for #{dir == '' ? 'root directory' : dir}", caller
		end

		super(title, dir, dir, true)
		
		@templateFile = File.join(cfg.srcDirectory, dir, cfg.templateFile)
		if !File.exists?(@templateFile)
			if dir == '' # dir is root directory
				raise ThgException.new("create an #{cfg.templateFile} in the root directory"),
					"directory index file in root directory not found", caller
			end
			@templateFile = parentTemplateFile
		end
	end
	
end
=end
