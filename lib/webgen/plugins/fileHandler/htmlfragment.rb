require 'webgen/plugins/fileHandler/pagePlugin'

class HTMLPage < PagePlugin

    NAME = "HTML Page Plugin"
    SHORT_DESC = "Handles HTML webpage fragments"

    EXTENSION = 'fragment'

    def init
        child_init
    end


    def get_file_data( srcName )
        data = Hash.new
        data['content'] = File.new( srcName ).read
        data
    end

end

UPS::Registry.register_plugin HTMLPage

