require 'node'
require 'plugins/fileHandler/fileHandler'

class DirHandlerPlugin < UPS::Plugin

    NAME = "Dir Handler"
    SHORT_DESC = "Handles directories"

    def init
        UPS::Registry['File Handler'].extensions[:dir] = self
    end

    def create_node( path, parent )
        relName = File.basename path
        node = Node.new parent
        node['title'] = relName
        node['src'] = node['dest'] = relName + File::SEPARATOR
        node
    end

    def write_node( node )
        name = node.recursive_value 'dest'
        FileUtils.makedirs( name ) unless File.exists? name
	end

end

UPS::Registry.register_plugin DirHandlerPlugin
