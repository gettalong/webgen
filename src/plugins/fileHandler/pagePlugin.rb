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

    ThgException.add_entry :PAGE_TEMPLATE_FILE_NOT_FOUND,
		"template file in root directory not found",
		"create an %0 in the root directory"

    attr_reader :templateFile
    attr_reader :directoryIndexFile

    EXTENSION = 'page'


    def initialize
        #TODO config = Configuration.instance.pluginData['xmlPagePlugin']
        #TODO raise ThgException.new(ThgException::CFG_ENTRY_NOT_FOUND, 'xmlPagePlugin') if config.nil?

        @defaultTemplate =  'default.template' #TODO config.text('templateFile')
        @defaultDirectoryIndex = 'index.page'  #TODO config.text('directoryIndexFile')
    end


    def init
        UPS::Registry['File Handler'].extensions[EXTENSION] = self
        UPS::Registry['File Handler'].add_msg_listener( :AFTER_DIR_READ, method( :add_template_to_node ) )
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
        templateNode = get_template_for_node( node )

        outstring = templateNode['content'].dup

        #UPS::PluginRegistry.instance['tags'].substituteTags(node.metainfo['content'], node)
        UPS::Registry['Tags'].substitute_tags( outstring, node, templateNode )

        File.open( filename, File::CREAT|File::TRUNC|File::RDWR ) do |file|
            file.write outstring
        end
    end

    #######
    private
    #######

    def add_template_to_node( node )
        cfg = UPS::Registry['Configuration']

        if node.find { |child| child['src'] == @defaultDirectoryIndex }.nil?
            #TODO Configuration.instance.warning("directory index file for #{node.abs_src} not found")
        end

        templateNode = node.find { |child| child['src'] == @defaultTemplate }
        if !templateNode.nil?
            node['templateFile'] = templateNode
        elsif node.parent.nil? # dir is root directory
            raise ThgException.new( :PAGE_TEMPLATE_FILE_NOT_FOUND, @defaultTemplate )
        end
    end


    def get_template_for_node( node )
        raise "Template file for node not found -> this should not happen!" if node.nil?
        if node.metainfo.has_key? 'templateFile'
            return node['templateFile']
        else
            return get_template_for_node( node.parent )
        end
    end

end

UPS::Registry.register_plugin XMLPagePlugin

