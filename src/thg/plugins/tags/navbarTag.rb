require 'ups/ups'
require 'plugins/tags/tags'

class NavbarTag < UPS::Plugin

    NAME = 'Navigation Bar Tag'
    SHORT_DESC = 'Shows the hierarchy of current page'

    def init
        @separator = UPS::Registry['Configuration'].get_config_value( NAME, 'separator', ' / ' )
        @startTag = UPS::Registry['Configuration'].get_config_value( NAME, 'startTag', '' )
        @endTag = UPS::Registry['Configuration'].get_config_value( NAME, 'endTag', '' )
        UPS::Registry['Tags'].tags['navbar'] = self
    end


    def process_tag( tag, content, srcNode, refNode )
        out = []
        node = srcNode

        until node.nil?
            out.push( node['processor'].get_html_link( node, srcNode ) )
            node = node.parent
            node = node.parent while !node.nil? && node['virtual']
        end

        out = @startTag + out.reverse.join(@separator) + @endTag
        self.logger.debug out
        out
    end

end

UPS::Registry.register_plugin NavbarTag
