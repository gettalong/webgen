require 'composite'

class Node
	
	include Composite

	attr_reader   :parent
	attr_accessor :title
	attr_accessor :url
	attr_accessor :src
	attr_accessor :processor

	attr_reader   :metainfo
	
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
			src.dup
		else
			parent.abs_src << src
		end
	end

	def abs_url
		if parent.nil?
			url.dup
		else
			parent.abs_url << url
		end
	end

end
