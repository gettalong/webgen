require 'ups/ups'
require 'ups/listener'
require 'configuration'

class TreeTransformer < UPS::Plugin

    include Listener

    NAME = "Tree Transformer"
    SHORT_DESC = "Super plugin for transforming the data tree"

    def initialize
        add_msg_name :execute
    end

	def execute( tree )
        dispatch_msg :execute, tree
	end

end


class DebugTreePrinter < UPS::Plugin

    NAME = "Debug Tree Printer"
    SHORT_DESC = "Prints out the information in the tree for debug purposes."

    def init
        UPS::Registry[TreeTransformer::NAME].add_msg_listener( :execute, method( :execute ) )
    end

	def execute( node, level = 0 )
		# just print all the nodes
        #TODO Log4r style
        print "   "*level  << "\\_ "*(level > 0 ? 1 : 0) <<  "#{node['title']}: #{node['src']} -> #{node['dest']}\n"
		node.each do |child|
			execute( child, level + 1 )
		end
	end

end

UPS::Registry.instance.register_plugin( TreeTransformer )
UPS::Registry.instance.register_plugin( DebugTreePrinter ) if UPS::Registry['Configuration'].verbosityLevel >= 2
