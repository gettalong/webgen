require 'ups/ups'

class TreeUtils < UPS::Plugin

    NAME = "Tree Utils"
    SHORT_DESC = "Provides various functions for the internal tree structure"


    def get_relpath_to_node( srcNode, destNode )
        i = ( srcNode.children.nil? ? -2 : -1 ) # do not count file + directory or directory
        until srcNode.nil?
            i += 1 unless srcNode['virtual']
            srcNode = srcNode.parent
        end
        ( ".." + File::SEPARATOR )*i + destNode.parent.recursive_value( 'dest' ).sub(/^#{UPS::Registry['Configuration'].outDirectory + File::SEPARATOR}/, "")
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
