require 'ups'

class Tags < UPS::Controller

	def initialize
		super('tags')
	end

end


class TitleTag < UPS::StandardPlugin
	
	def initialize
		super('tags', 'title')
	end

	def execute(element, node)
		element.parent.insert_after(element, REXML::Text.new(node.title, true))
		element.parent.delete(element)
	end

end

class ContentTag < UPS::StandardPlugin
	
	def initialize
		super('tags', 'content')
	end

	def execute(element, node)
		pre = element
		node.content.elements['content'].each_child { |child|
			if child.kind_of? REXML::Parent
				child = child.deep_clone
			else
				child = child.clone
			end
			
			element.parent.insert_after(pre, child)
			pre = child
		}
		element.parent.delete(element)
	end

end

UPS::PluginRegistry.instance.register_plugin(Tags.new)
UPS::PluginRegistry.instance.register_plugin(TitleTag.new)
UPS::PluginRegistry.instance.register_plugin(ContentTag.new)
