
class Node
	
	attr_reader   :title
	attr_reader   :url
	attr_reader   :virtual
	attr_accessor :content
	
	def initialize(title, url, virtual)
		@title = title
		@url = url
		@virtual = virtual
	end

end


class Tree

	attr_reader :root

	def initialize
	end

end
