require 'ups'

class ThgListPlugin < UPS::StandardPlugin

	def initialize
		super('listRegistry', 'thgPluginList')
	end

	def describe
		"Pretty prints the controller and plugin describtions"
	end

	def after_register
		UPS::PluginRegistry.instance['listRegistry'].set_plugin('thgPluginList')
	end

	def processController(order, controller)
		if order == UPS::ListController::BEFORE
			print "Controller group '#{controller.id}':\n"
		else
			print "\n"
		end
	end

	def processPlugin(plugin)
		if plugin.respond_to? :describe
			print "  Plugin '#{plugin.id}:'\n"
			width = 0;
			print "    "+plugin.describe.split(' ').collect {|s|
				width += s.length
				ret = ""
				if width > 60
					ret << "\n    "
					width = 0
				end
				ret << s << ' '
			}.join('') + "\n\n"
		end
	end

end

UPS::PluginRegistry.instance.register_plugin(ThgListPlugin.new)
