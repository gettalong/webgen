require 'rexml/document'
require 'thgexception'
require 'plugins/fileHandler/pagePlugin'

class XMLPagePlugin < PagePlugin

    NAME = "XML Page Plugin"
    SHORT_DESC = "Handles XML webpage description files"

    ThgException.add_entry :PAGE_META_ENTRY_NOT_FOUND,
		"the tag <%0> has not be found in the <meta> section of the page file %1",
		"<%0> is not optional, you have to add it to the page file"

    attr_reader :defaultTemplate
    attr_reader :defaultDirectoryIndex

    EXTENSION = 'page'

    def init
        super
    end


    def create_node( srcName, parent )
        root = REXML::Document.new( File.new( srcName ) ).root

        srcName = File.basename srcName
        urlName = srcName.gsub( /\.#{EXTENSION}$/, '.html' )

        node = Node.new parent
        node['title'] = root.text( '/thg/metainfo/title' )
        node['templateFile'] = root.text('/thg/metainfo/template') unless root.text('/thg/metainfo/template').nil?
        node['inMenu'] = root.text('/thg/metainfo/inMenu') unless root.text('/thg/metainfo/inMenu').nil?
        node['src'] = srcName
        node['dest'] = urlName
        node['content'] = ''
        root.elements['content'].each do
            |child| child.write( node['content'] )
        end

        return node
    end

end

UPS::Registry.register_plugin XMLPagePlugin

