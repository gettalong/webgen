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

    attr_reader :indexFile

    def init
        @indexFile = UPS::Registry['Configuration'].get_config_value( NAME, 'indexFile' ) || 'index.html'
        UPS::Registry['File Handler'].extensions[:dir] = self
        UPS::Registry['File Handler'].add_msg_listener( :AFTER_DIR_READ, method( :process_dir_index ) )
    end

    def create_node( path, parent )
        DirNode.new( parent, File.basename( path ) )
    end

    def write_node( node )
        name = node.recursive_value 'dest'
        FileUtils.makedirs( name ) unless File.exists? name
	end

    #######
    private
    #######

    def process_dir_index( dirNode )
        node, created = UPS::Registry['Page Plugin'].get_page_node( @indexFile, dirNode )
        if created
            self.logger.error { "No directory index file found for directory <#{dirNode.recursive_value( 'src' )}>" }
        else
            self.logger.info { "Directory index file for <#{dirNode.recursive_value( 'src' )}> => <#{node['pageBasename']}>" }
        end
        dirNode['indexFile'] = node
        node.each do |child| child['directoryName'] ||= dirNode['title'] end
    end

end

UPS::Registry.register_plugin DirHandlerPlugin
