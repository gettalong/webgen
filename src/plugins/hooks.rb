require 'ups'
require 'configuration'

class Hook < UPS::Controller

	def initialize
		super('hook')
		@hooks = Hash.new
	end

	def describe
		"Provides hooking facilities to plugins."
	end

	def add_hook(hookname, publisher)
		if @hooks.has_key? hookname
			return false
		end

		@hooks[hookname] = publisher
	end

	def del_hook(hookname)
		@hooks.delete(hookname)
	end

	def add_listener(hookname, callableObject = nil, &block)
		return if !@hooks.has_key? hookname

		@hooks[hookname].add_listener(hookname, callableObject, &block)
	end

	def list_hooks
		@hooks.keys
	end

end

UPS::PluginRegistry.instance.register_plugin(Hook.new)
