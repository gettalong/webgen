require 'ups/ups'
require 'plugins/tags/tags'

class LangTag < UPS::Plugin

    NAME = 'Language Tag'
    SHORT_DESC = 'Provides a link to translations of the page'

    def init
        UPS::Registry['Tags'].tags['lang'] = self
    end


	def process_tag( tag, content, node, templateNode )
        node.parent.children.sort { |a, b| a['lang'] <=> b['lang'] }.collect do |node|
            "<a href=\"#{node['dest']}\">#{node['lang']}</a>"
        end.join('&nbsp;|&nbsp;')
	end

end

UPS::Registry.register_plugin LangTag
