require 'ups/ups'

class TreeUtils < UPS::Plugin

    NAME = "Tree Utils"
    SHORT_DESC = "Provides various functions for the internal tree structure"


    def get_relpath_to_node( srcNode, destNode )
        #TODO solve this problem an other way
        if srcNode.children.nil?
            i = -2 # do not count file + current directory
        else
            i = -1
        end
        ( i += 1; srcNode = srcNode.parent ) until srcNode.nil? # how many levels?
        ( ".." + File::SEPARATOR )*i + destNode.parent.recursive_value( 'dest' ).sub(/^#{UPS::Registry['Configuration'].outDirectory + File::SEPARATOR}/, "")
    end


    def get_node_for_string( srcNode, destString )
        node = srcNode.parent
        destString.split(File::SEPARATOR).each do |element|
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
