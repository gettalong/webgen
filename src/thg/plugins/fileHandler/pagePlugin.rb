require 'thg/plugins/nodeProcessor'
require 'thg/plugins/fileHandler/fileHandler'

class PageNode < Node

    def initialize( parent, basename )
        super parent
        self['page:basename'] = self['title'] = basename
        self['src'] = self['dest'] = ''
        self['virtual'] = true
    end

end


class PagePlugin < UPS::Plugin

    include NodeProcessor

    NAME = "Page Plugin"
    SHORT_DESC = "Super class for all page plugins"

    ThgException.add_entry :PAGE_TITLE_ENTRY_NOT_FOUND,
        "the file <%0> does not contain a title tag",
        "add a title tag or remove the file"


    def create_node( srcName, parent )
        data = get_file_data srcName

        fileData = analyse_file_name( File.basename( srcName ) )

        pageNode, created = get_page_node( fileData.baseName, parent )

        node = Node.new pageNode
        node.metainfo = data
        node['src'] = fileData.srcName
        node['dest'] = fileData.urlName
        node['lang'] ||= fileData.lang
        node['title'] ||= fileData.title
        node['menuOrder'] ||= fileData.menuOrder
        node['processor'] = self
        pageNode.add_child node

        return ( created ? pageNode : nil )
    end


    def write_node( node )
        # do nothing if page base node
        return unless node['virtual'].nil?
        templateNode = UPS::Registry['Template File'].get_template_for_node( node )

        outstring = templateNode['content'].dup

        UPS::Registry['Tags'].substitute_tags( outstring, node, templateNode )

        File.open( node.recursive_value( 'dest' ), File::CREAT|File::TRUNC|File::RDWR ) do |file|
            file.write outstring
        end
    end


    def get_page_node( basename, dirNode )
        node = dirNode.find do |node| node['page:basename'] == basename end
        if node.nil?
            node = PageNode.new( dirNode, basename )
            created = true
        end
        [node, created]
    end


    def get_lang_node( node, lang = node['lang'] )
        node = node.parent unless node['page:basename']
        langNode = node.find do |child| child['lang'] == lang end
        langNode = node.find do |child| child['lang'] == UPS::Registry['Configuration'].lang end if langNode.nil?
        if langNode.nil?
            langNode = node.children[0]
            self.logger.warn do
                "No node in language '#{lang}' nor the default language (#{UPS::Registry['Configuration'].lang}) found,"+
                " using first available node for page file <#{node['title']}>"
            end
        end
        langNode
    end


    #########
    protected
    #########

    def child_init
        UPS::Registry['File Handler'].extensions[self.class::EXTENSION] = self
    end

    #######
    private
    #######


    def analyse_file_name( srcName )
        matchData = /^((\d+)\.)?([^.]*?)(\.(\w\w))?\.#{self.class::EXTENSION}$/.match srcName
        fileData = Struct.new(:baseName, :srcName, :urlName, :menuOrder, :title, :lang).new

        fileData.lang      = matchData[5] || UPS::Registry['Configuration'].lang
        fileData.baseName  = matchData[3] + '.html'
        fileData.srcName   = srcName
        fileData.urlName   = matchData[3] + '.' + fileData.lang + '.html'
        fileData.menuOrder = matchData[2].to_i
        fileData.title     = matchData[3].tr('_-', ' ').capitalize

        fileData
    end

end

UPS::Registry.register_plugin PagePlugin
