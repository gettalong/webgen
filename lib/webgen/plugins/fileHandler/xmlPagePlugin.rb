require 'rexml/document'
require 'webgen/plugins/fileHandler/pagePlugin'

class XMLPagePlugin < PagePlugin

    NAME = "XML Page Plugin"
    SHORT_DESC = "Handles XML webpage description files"

    EXTENSION = 'xpage'

    def init
        child_init
    end


    def get_file_data( srcName )
        root = REXML::Document.new( File.new( srcName ) ).root

        #TODO rework this sothat arbitrary tags can be included
        data = Hash.new
        data['title'] = root.text( '/webgen/title' )
        data['templateFile'] = root.text('/webgen/template') unless root.text('/webgen/template').nil?
        data['inMenu'] = root.text('/webgen/inMenu') unless root.text('/webgen/inMenu').nil?
        data['menuOrder'] = root.text('/webgen/menuOrder').to_i unless root.text('/webgen/menuOrder').nil?
        data['content'] = ''
        root.elements['content'].each do
            |child| child.write( data['content'] )
        end

        return data
    end

end

UPS::Registry.register_plugin XMLPagePlugin
