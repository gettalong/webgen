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
            out.push( node['processor'].get_html_link( node, srcNode ) )
            node = node.parent
            node = node.parent while !node.nil? && node['virtual']
        end

        out = out.reverse.join(' / ')
        self.logger.debug out
        out
	end

end

UPS::Registry.register_plugin NavbarTag
