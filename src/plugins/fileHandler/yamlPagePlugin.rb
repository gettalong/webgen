require 'yaml'
require 'plugins/fileHandler/pagePlugin'

class YAMLPagePlugin < PagePlugin

    NAME = "YAML Page Plugin"
    SHORT_DESC = "Handles YAML webpage description files"

    EXTENSION = 'ypage'

    def init
        child_init
    end


    def get_file_data( srcName )
        YAML::load( File.new( srcName ) )
    end

end

UPS::Registry.register_plugin YAMLPagePlugin
