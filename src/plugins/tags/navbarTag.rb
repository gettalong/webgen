require 'ups/ups'
require 'plugins/tags/tags'

class NavbarTag < UPS::Plugin

    NAME = 'Navigation Bar Tag'
    SHORT_DESC = 'Shows the hierarchy of current page'

    def init
        UPS::Registry['Tags'].tags['navbar'] = self
    end


	def process_tag( tag, content, srcNode, templateNode )
        out = []
        node = srcNode

        until node.nil?
            if node.instance_of? DirNode
                tempNode = node['processor'].get_lang_node( node, srcNode['lang'] )
                title = tempNode['directoryName']
            else
                tempNode = node
                title = node['title']
            end

            url = UPS::Registry['Tree Utils'].get_relpath_to_node( srcNode, tempNode ) + tempNode['dest']
            out.push "<a href=\"#{url}\">#{title}</a>"
            node = node.parent
            node = node.parent while !node.nil? && node['virtual']
        end

        out = out.reverse.join(' / ')
        self.logger.debug out
        out
	end

end

UPS::Registry.register_plugin NavbarTag
