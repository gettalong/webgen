require 'util/ups'
require 'util/listener'

class TreeTransformer < UPS::Plugin

    include Listener

    NAME = "Tree Transformer"
    SHORT_DESC = "Super plugin for transforming the data tree"

    def initialize
        add_msg_name :preorder
        add_msg_name :postorder
    end

    def execute( tree, level = 0 )
        dispatch_msg :preorder, tree, level
        tree.each do |child|
            execute( child, level + 1 )
        end
        dispatch_msg :postorder, tree, level
    end

end


class DebugTreePrinter < UPS::Plugin

    NAME = "Debug Tree Printer"
    SHORT_DESC = "Prints out the information in the tree for debug purposes."

    def init
        UPS::Registry[TreeTransformer::NAME].add_msg_listener( :preorder, method( :execute ) )
    end

    def execute( node, level )
        self.logger.debug { "   "*level  << "\\_ "*(level > 0 ? 1 : 0) << (node['virtual'] ? "[V]" : "") << "#{node['title']}: #{node['src']} -> #{node['dest']}" }
    end

end

UPS::Registry.instance.register_plugin( TreeTransformer )
UPS::Registry.instance.register_plugin( DebugTreePrinter )
