#
# Module Composite
#
# Implementation of the Composite pattern
#
# $Id$
#

module Composite
	
	include Enumerable

	attr_reader :children
	
	def init_composite
		@children = Array.new
	end

	def add_children(array)
		if array.instance_of? Array
			@children = array
		else
			raise "Parameter must be array"
		end
	end

	def del_children
		@children = Array.new
	end
	
	def add_child(child)
		@children.push(child)
	end

	def del_child(child)
		if child.instance_of? Integer
			@children.delete_at(child)
		else
			@children.delete(child)
		end
	end

	def each
		children.each { |child| yield(child) }
	end

end
