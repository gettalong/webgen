require 'node'
require 'plugins/fileHandler/fileHandler'

class DirNode < Node

    def initialize( parent, name )
        super parent
        self.metainfo['title'] = name
        self.metainfo['src'] = self.metainfo['dest'] = name + File::SEPARATOR
    end

end

class DirHandlerPlugin < UPS::Plugin

    NAME = "Dir Handler"
    SHORT_DESC = "Handles directories"

    def init
        UPS::Registry['File Handler'].extensions[:dir] = self
    end

    def create_node( path, parent )
        DirNode.new( parent, File.basename( path ) )
    end

    def write_node( node )
        name = node.recursive_value 'dest'
        FileUtils.makedirs( name ) unless File.exists? name
	end

end

UPS::Registry.register_plugin DirHandlerPlugin
