require 'ups/ups'
require 'thgexception'
require 'node'
require 'plugins/fileHandler/fileHandler'
require 'plugins/treeTransformer'
require 'configuration'

class TemplatePlugin < UPS::Plugin

    NAME = "Template File"
    SHORT_DESC = "Represents the template files for the page generation in the tree"

    ThgException.add_entry :PAGE_TEMPLATE_FILE_NOT_FOUND,
		"template file in root directory not found",
		"create an %0 in the root directory"

	EXTENSION = 'template'


    attr_reader :defaultTemplate

	def init
        @defaultTemplate = UPS::Registry['Configuration'].get_config_value( NAME, 'defaultTemplate' ) || 'default.template'
		UPS::Registry['File Handler'].extensions[EXTENSION] = self
        UPS::Registry['File Handler'].add_msg_listener( :AFTER_DIR_READ, method( :add_template_to_node ) )
	end


	def create_node( srcName, parent )
		relName = File.basename srcName
		node = Node.new parent
        node['title'] = 'Template'
        node['src'] = node['dest'] = relName
		File.open( srcName ) do |file|
			node['content'] = file.read
		end
		return node
	end


	def write_node( node )
		# do not write anything
	end


    def get_template_for_node( node )
        raise "Template file for node not found -> this should not happen!" if node.nil?
        if node.metainfo.has_key? 'templateFile'
            return node['templateFile']
        else
            return get_template_for_node( node.parent )
        end
    end


    #######
    private
    #######

    def add_template_to_node( node )
        templateNode = node.find { |child| child['src'] == @defaultTemplate }
        if !templateNode.nil?
            node['templateFile'] = templateNode
        elsif node.parent.nil? # dir is root directory
            raise ThgException.new( :PAGE_TEMPLATE_FILE_NOT_FOUND, @defaultTemplate )
        end
    end


end


class TemplateTreeWalker < UPS::Plugin

    NAME = "Template Tree Walker"
    SHORT_DESC = "Substitutes all 'templateFile' infos with the approriate node"

    def init
        UPS::Registry['Tree Transformer'].add_msg_listener( :preorder, method( :execute ) )
    end

    def execute( node, level )
        if node.metainfo.has_key?( "templateFile" ) && node['templateFile'].kind_of?( String )
            templateNode = UPS::Registry['Tree Utils'].get_node_for_string( node, node['templateFile'] )
            if templateNode.nil?
                self.logger.warn { "Specified template for file <#{node['src']}> not found!!!" }
                node.metainfo.delete "templateFile"
            else
                node['templateFile'] = templateNode
                self.logger.info { "Replacing 'templateFile' in <#{node['src']}> with <#{templateNode['src']}>" }
            end
        end
    end

end


UPS::Registry.register_plugin TemplatePlugin
UPS::Registry.register_plugin TemplateTreeWalker
