require 'yaml'
require 'plugins/fileHandler/pagePlugin'

class YAMLPagePlugin < PagePlugin

    NAME = "YAML Page Plugin"
    SHORT_DESC = "Handles YAML webpage description files"

    EXTENSION = 'yaml'

    def init
        super
    end


    def create_node( srcName, parent )
        data = YAML::load( File.new( srcName ) )

        srcName = File.basename srcName
        urlName = srcName.gsub( /\.#{EXTENSION}$/, '.html' )

        node = Node.new parent
        node['title'] = data['metainfo']['title']
        node['templateFile'] = data['metainfo']['template'] unless data['metainfo']['template'].nil?
        node['inMenu'] = data['metainfo']['inMenu'] unless data['metainfo']['inMenu'].nil?
        node['src'] = srcName
        node['dest'] = urlName
        node['content'] = data['content']

        return node
    end

end

UPS::Registry.register_plugin YAMLPagePlugin
