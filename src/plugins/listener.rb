
module Listener
	
	def add_listener(msgName, callableObject = nil, &block)
		return if !@msgNames.has_key? msgName
		
		if !callableObject.nil?
			@msgNames[msgName].push(callableObject)
		elsif !block.nil?
			@msgNames[msgName].push(block)
		else
			raise "you have to define a callback object"
		end
	end

	#######
	private
	#######

	def dispatch(msgName, *args)
		@msgNames[msgName].each {|obj|
			obj.call(*args)
		}
	end

end
