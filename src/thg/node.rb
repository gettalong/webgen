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


    # Returns the relative path from the srcNode to the destNode. The srcNode
    # is normally a page file node, but the method should work for other nodes
    # too. The destNode can be any non virtual node.
    def get_relpath_to_node( destNode )
        path = @parent.recursive_value( 'dest' )[UPS::Registry['Configuration'].outDirectory.length+1..-1]
        path = path.gsub(/.*?(#{File::SEPARATOR})/, "..#{File::SEPARATOR}")
        path += destNode.parent.recursive_value( 'dest' )[UPS::Registry['Configuration'].outDirectory.length+1..-1] unless destNode.parent.nil?
        path
    end


    # Returns the node identified by the given string relative to the current node.
    def get_node_for_string( destString )
        if /^#{File::SEPARATOR}/ =~ destString
            node = Node.root(self)
            destString = destString[1..-1]
        else
            node = @parent
        end

        destString.split(File::SEPARATOR).each do |element|
            node = node.parent while node['virtual']
            case element
            when '..'
                node = node.parent
            else
                node = node.find do |child| /#{element}#{File::SEPARATOR}?/ =~ child['src'] end
            end
            if node.nil?
                self.logger.error { "Could not get destination node for <#{metainfo['src']}> with '#{destString}'" }
                return
            end
        end

        return node
    end


    def Node.root( node )
        node = node.parent until node.parent.nil?
        node
    end

end
