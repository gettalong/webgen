require 'ups/composite'

class Node

	include Composite

	attr_reader   :parent
	attr_accessor :metainfo

	def initialize( parent )
		@parent = parent
		@metainfo = Hash.new
	end

    def []( name )
        @metainfo[name]
    end

    def []=( name, value )
        @metainfo[name] = value
    end

    def recursive_value( name )
        if @parent.nil?
			@metainfo[name].dup
		else
			@parent.recursive_value( name ) + @metainfo[name]
		end
	end

    def Node.root( node )
        node = node.parent until node.parent.nil?
        node
    end

end
