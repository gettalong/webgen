require 'ups/ups'
require 'node'
require 'plugins/fileHandler/fileHandler'


class PagePlugin < UPS::Plugin

    def init
        UPS::Registry['File Handler'].extensions[self.class::EXTENSION] = self
    end


    def create_node( srcName, parent )
        data = get_file_data srcName

        srcName, urlName, baseName, lang = get_file_names srcName

        pageNode, created = get_page_node( baseName, parent )

        node = Node.new pageNode
        node.metainfo = data['metainfo']
        node['src'] = srcName
        node['dest'] = urlName
        node['lang'] = lang
        node['content'] = data['content']
        node['processor'] = self

        pageNode.add_child node

        return ( created ? pageNode : nil )
    end


    def write_node( node )
        # do nothing if page base node
        return unless node['virtual'].nil?
        templateNode = UPS::Registry['Template File'].get_template_for_node( node )

        outstring = templateNode['content'].dup

        #UPS::PluginRegistry.instance['tags'].substituteTags(node.metainfo['content'], node)
        UPS::Registry['Tags'].substitute_tags( outstring, node, templateNode )

        File.open( node.recursive_value( 'dest' ), File::CREAT|File::TRUNC|File::RDWR ) do |file|
            file.write outstring
        end
    end

    #######
    private
    #######

    def get_file_names( srcName )
        srcName = File.basename srcName
        lang = ''
        urlName = srcName.sub( /(\.\w\w)?\.#{self.class::EXTENSION}$/ ) do |match|
            lang = $1.nil? ? UPS::Registry['Configuration'].defaultLang : $1[1..-1]
            ".#{lang}.html"
        end
        baseName = srcName.sub( /(\.\w\w)?\.#{self.class::EXTENSION}$/, '.html' )
        [srcName, urlName, baseName, lang]
    end


    def get_page_node( basename, dirNode )
        node = dirNode.find do |node| node['pageBasename'] == basename end
        if node.nil?
            node = Node.new dirNode
            node['pageBasename'] = node['title'] = basename
            node['src'] = node['dest'] = ''
            node['virtual'] = true
            created = true
        end
        [node, created]
    end


end
