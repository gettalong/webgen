require 'ups/ups'
require 'node'
require 'plugins/nodeProcessor'
require 'plugins/fileHandler/fileHandler'

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

        srcName, urlName, baseName, lang = get_file_names srcName

        pageNode, created = get_page_node( baseName, parent )

        node = Node.new pageNode
        node.metainfo = data
        node['src'] = srcName
        node['dest'] = urlName
        node['lang'] = lang
        node['processor'] = self
        node['title'] ||= get_default_title srcName
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


    def get_file_names( srcName )
        srcName = File.basename srcName
        lang = ''
        urlName = srcName.sub( /(\.\w\w)?\.#{self.class::EXTENSION}$/ ) do |match|
            lang = $1.nil? ? UPS::Registry['Configuration'].lang : $1[1..-1]
            ".#{lang}.html"
        end
        baseName = srcName.sub( /(\.\w\w)?\.#{self.class::EXTENSION}$/, '.html' )
        [srcName, urlName, baseName, lang]
    end


    def get_default_title( srcName )
        name = srcName.gsub(/^(\d+\.)?/, '').gsub(/(\.\w\w)?\.[^.]*?$/, '').tr('_-', ' ')
        name[0..0].upcase + name[1..-1]
    end

end

UPS::Registry.register_plugin PagePlugin
