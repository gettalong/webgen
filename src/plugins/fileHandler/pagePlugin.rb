require 'ups/ups'
require 'node'
require 'plugins/fileHandler/fileHandler'

class PagePlugin < UPS::Plugin

    def init
        UPS::Registry['File Handler'].extensions[self.class::EXTENSION] = self
    end


    def write_node( node )
        return unless UPS::Registry['File Handler'].file_modified?( node )

        templateNode = UPS::Registry['Template File'].get_template_for_node( node )

        outstring = templateNode['content'].dup

        #UPS::PluginRegistry.instance['tags'].substituteTags(node.metainfo['content'], node)
        UPS::Registry['Tags'].substitute_tags( outstring, node, templateNode )

        File.open( node.recursive_value( 'dest' ), File::CREAT|File::TRUNC|File::RDWR ) do |file|
            file.write outstring
        end
    end

end
