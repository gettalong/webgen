require 'thg/plugins/nodeProcessor'
require 'thg/plugins/fileHandler/fileHandler'

class PageFileBacking < UPS::Plugin

    include NodeProcessor

    NAME = "PageFileBacking"
    SHORT_DESC = "Handles backing files for page file types with no metainfo"

    def init
        @backingFile = UPS::Registry['Configuration'].get_config_value( NAME, 'backingFile', 'metainfo.backing' )
        UPS::Registry['File Handler'].extensions['backing'] = self
        UPS::Registry['File Handler'].add_msg_listener( :AFTER_DIR_READ, method( :process_backing_file ) )
    end


    def create_node( path, parent )
        node = Node.new parent
        node['virtual'] = true
        node['src'] = node['dest'] = node['title'] = File.basename( path )
        node['content'] = YAML::load( File.new( path ) )
        node
    end


    def write_node( node )
        # nothing to write
    end


    #######
    private
    #######


    def process_backing_file( dirNode )
        backingFile = dirNode.find do |child| child['src'] == @backingFile end
        return if backingFile.nil?

        backingFile['content'].each do |filename, data|
            backedFile = dirNode.find do |child| child['title'] == filename end
            if backedFile
                data.each do |language, fileData|
                    langFile = UPS::Registry['Page Plugin'].get_lang_node( backedFile, language )
                    next unless langFile['lang'] == language

                    self.logger.info { "Setting meta info data on file <#{langFile.recursive_value( 'dest' )}>" }
                    langFile.metainfo.update fileData
                end
            end
        end
    end

end

UPS::Registry.register_plugin PageFileBacking
