require 'yaml'
require 'ups/ups'
require 'thgexception'
require 'node'
require 'plugins/fileHandler/fileHandler'

class YAMLPagePlugin < UPS::Plugin

    NAME = "YAML Page Plugin"
    SHORT_DESC = "Handles YAML webpage description files"

    EXTENSION = 'yaml'

    def init
        UPS::Registry['File Handler'].extensions[EXTENSION] = self
    end


    def create_node( srcName, parent )
        data = YAML::load( File.new( srcName ) )

        srcName = File.basename srcName
        urlName = srcName.gsub( /\.#{EXTENSION}$/, '.html' )

        node = Node.new parent
        node['title'] = data['metainfo']['title']
        node['src'] = srcName
        node['dest'] = urlName
        node['content'] = data['content']

        return node
    end


    def write_node( node, filename )
        templateNode = UPS::Registry['Template File'].get_template_for_node( node )

        outstring = templateNode['content'].dup

        #UPS::PluginRegistry.instance['tags'].substituteTags(node.metainfo['content'], node)
        UPS::Registry['Tags'].substitute_tags( outstring, node, templateNode )

        File.open( filename, File::CREAT|File::TRUNC|File::RDWR ) do |file|
            file.write outstring
        end
    end

end

UPS::Registry.register_plugin YAMLPagePlugin
