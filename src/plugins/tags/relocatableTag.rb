require 'ups/ups'
require 'plugins/tags/tags'

class RelocatableTag < UPS::Plugin

    NAME = 'Relocatable Tag'
    SHORT_DESC = 'Adds a relative path to the specified name if necessary'

    def init
        UPS::Registry['Tags'].tags['relocatable'] = self
    end

	def process_tag( path, node, templateNode )
        get_relpath_to_template( node, templateNode) + path
	end


    def get_relpath_to_template( node, template )
        i = -2 # do not count file + current directory
        (i += 1; node = node.parent) until node.nil?
        (".." + File::SEPARATOR)*i + template.parent.recursive_value('dest')
    end


end

UPS::Registry.register_plugin RelocatableTag
