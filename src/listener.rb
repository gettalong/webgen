module Listener

	def add_msg_listener(msgName, callableObject = nil, &block)
		return unless defined? @msgNames and @msgNames.has_key? msgName

		if !callableObject.nil?
            raise NoMethodError, "listener needs to respond to 'call'" unless callableObject.respond_to? :call
			@msgNames[msgName].push callableObject
		elsif !block.nil?
			@msgNames[msgName].push block
		else
			raise "you have to provide a callback object or a block"
		end
	end

	def del_msg_listener(msgName, object)
		@msgNames[msgName].delete object if defined? @msgNames
	end

	#######
	private
	#######

	def add_msg_name(msgName)
        @msgNames = {}  unless defined? @msgNames
		@msgNames[msgName] = [] unless @msgNames.has_key? msgName
	end

	def del_msg_name(msgName)
		@msgNames.delete msgName if defined? @msgNames
	end

	def dispatch_msg(msgName, *args)
        if defined? @msgNames and @msgNames.has_key? msgName
            @msgNames[msgName].each do |obj|
                obj.call *args
            end
        end
    end

    private :add_msg_name, :del_msg_name, :dispatch_msg

end


if __FILE__ == $0

	class Test

		include Listener

		def initialize
			add_msg_name(:test)
		end

		def dispatch_it(i)
			dispatch_msg(:test, i)
		end
	end

	def doit(i)
		p i
	end


	t = Test.new
	t.add_msg_listener(:test, method(:doit))
	t.dispatch_it('hallo')
	p t.inspect
	t.del_msg_listener(:test, method(:doit))
	t.dispatch_it('hallo')
	p t.inspect
end
