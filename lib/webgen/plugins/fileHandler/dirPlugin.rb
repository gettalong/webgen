require 'webgen/plugins/nodeProcessor'
require 'webgen/plugins/fileHandler/pagePlugin'

class DirNode < Node

    def initialize( parent, name )
        super parent
        self['title'] = self['directoryName'] = name
        self['src'] = self['dest'] = name + File::SEPARATOR
    end

end


class DirHandlerPlugin < UPS::Plugin

    include NodeProcessor

    NAME = "Dir Handler"
    SHORT_DESC = "Handles directories"

    attr_reader :indexFile

    def init
        @indexFile = UPS::Registry['Configuration'].get_config_value( NAME, 'indexFile', 'index.html' )
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


    def get_lang_node( node, lang = node['lang'] )
        if node['indexFile']
            node['indexFile']['processor'].get_lang_node( node['indexFile'], lang )
        else
            node
        end
    end


    def get_html_link( node, refNode, title = nil )
        node = get_lang_node( node, refNode['lang'] )
        title ||=  node['directoryName']
        super( node, refNode, title )
    end


    #######
    private
    #######


    def process_dir_index( dirNode )
        node, created = UPS::Registry['Page Plugin'].get_page_node( @indexFile, dirNode )
        if created
            self.logger.warn { "No directory index file found for directory <#{dirNode.recursive_value( 'src' )}>" }
        else
            self.logger.info { "Directory index file for <#{dirNode.recursive_value( 'src' )}> => <#{node['title']}>" }
            dirNode['indexFile'] = node
            node.each do |child| child['directoryName'] ||= dirNode['directoryName'] end
        end
    end

end

UPS::Registry.register_plugin DirHandlerPlugin
