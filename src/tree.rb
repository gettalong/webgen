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
