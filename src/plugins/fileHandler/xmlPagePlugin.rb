require 'rexml/document'
require 'ups/ups'
require 'thgexception'
require 'node'
require 'plugins/fileHandler/fileHandler'

class XMLPagePlugin < UPS::Plugin

    NAME = "XML Page Plugin"
    SHORT_DESC = "Handles XML webpage description files"

    ThgException.add_entry :PAGE_META_ENTRY_NOT_FOUND,
		"the tag <%0> has not be found in the <meta> section of the page file %1",
		"<%0> is not optional, you have to add it to the page file"

    attr_reader :defaultTemplate
    attr_reader :defaultDirectoryIndex

    EXTENSION = 'page'

    def init
        UPS::Registry['File Handler'].extensions[EXTENSION] = self
    end


    def create_node( srcName, parent )
        root = REXML::Document.new( File.new( srcName ) ).root

        # initialize attributes
        title = root.text( '/thg/metainfo/title' )
        raise ThgException.new( :PAGE_META_ENTRY_NOT_FOUND, 'title', srcName ) if title.nil?

        srcName = File.basename srcName
        urlName = srcName.gsub( /\.#{EXTENSION}$/, '.html' )

        node = Node.new parent
        node['title'] = title
        node['src'] = srcName
        node['dest'] = urlName
        node['content'] = ''
        root.elements['content'].each do
            |child| child.write( node['content'] )
        end

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

UPS::Registry.register_plugin XMLPagePlugin

