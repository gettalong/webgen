require 'fileutils'
require 'thg/plugins/nodeProcessor'
require 'thg/plugins/fileHandler/fileHandler'

class FileCopyPlugin < UPS::Plugin

    include NodeProcessor

    NAME = "Copy Files"
    SHORT_DESC = "Copies files from source to destination without modification"
    DESCRIPTION = <<-EOF.gsub( /^\s*/, '' ).gsub( /\n/, ' ' )
        Implements a generic file copy plugin. All the file types which are specified in the
        configuration file are copied without any transformation into the destination directory.
    EOF


    def init
        types = UPS::Registry['Configuration'].get_config_value( NAME, 'types', ['css', 'jpg', 'png', 'gif'] )
        unless types.nil?
            types.each do |type|
                UPS::Registry['File Handler'].extensions[type] ||= self
            end
        end
    end


    def create_node( srcName, parent )
        relName = File.basename srcName
        node = Node.new parent
        node['dest'] = node['src'] = node['title'] = relName
        node
    end


    def write_node( node )
        FileUtils.cp( node.recursive_value( 'src' ), node.recursive_value( 'dest' ) ) if UPS::Registry['File Handler'].file_modified?( node )
    end

end

UPS::Registry.register_plugin FileCopyPlugin
