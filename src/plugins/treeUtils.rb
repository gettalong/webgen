require 'ups/ups'

class TreeUtils < UPS::Plugin

    NAME = "Tree Utils"
    SHORT_DESC = "Provides various functions for the internal tree structure"

    # Returns the relative path from the srcNode to the destNode. The srcNode
    # has to be a page file node, otherwise it is likely that an exception is
    # thrown. The destNode can be any non virtual node.
    def get_relpath_to_node( srcNode, destNode )
        path = ''
        srcNode = ( srcNode.children.nil? ? srcNode.parent.parent.parent : srcNode.parent.parent ) # do not count file + directory or directory
        until srcNode.nil?
            path << ".." + File::SEPARATOR unless srcNode['virtual']
            srcNode = srcNode.parent
        end
        path += destNode.parent.recursive_value( 'dest' )[UPS::Registry['Configuration'].outDirectory.length+1..-1] unless destNode.parent.nil?
        path
    end


    def get_node_for_string( srcNode, destString )
        node = srcNode.parent
        destString.split(File::SEPARATOR).each do |element|
            node = node.parent while node['virtual']
            case element
            when '..'
                node = node.parent
            else
                node = node.find { |child| child['src'] == element }
            end
            if node.nil?
                self.logger.error { "Could not get destination node for <#{srcNode['src']}> with '#{destString}'" }
                return
            end
        end
        return node
    end


end

UPS::Registry.register_plugin TreeUtils
