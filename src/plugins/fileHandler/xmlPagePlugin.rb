require 'rexml/document'
require 'plugins/fileHandler/pagePlugin'

class XMLPagePlugin < PagePlugin

    NAME = "XML Page Plugin"
    SHORT_DESC = "Handles XML webpage description files"

    EXTENSION = 'xpage'

    def init
        child_init
    end


    def get_file_data( srcName )
        root = REXML::Document.new( File.new( srcName ) ).root

        data = Hash.new
        data['metainfo'] = Hash.new
        data['metainfo']['title'] = root.text( '/thg/metainfo/title' )
        data['metainfo']['templateFile'] = root.text('/thg/metainfo/template') unless root.text('/thg/metainfo/template').nil?
        data['metainfo']['inMenu'] = root.text('/thg/metainfo/inMenu') unless root.text('/thg/metainfo/inMenu').nil?
        data['content'] = ''
        root.elements['content'].each do
            |child| child.write( data['content'] )
        end

        return data
    end

end

UPS::Registry.register_plugin XMLPagePlugin

