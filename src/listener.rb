
module Listener
	
	def initialize(*arg)
		super(*arg)
		@msgNames = Hash.new
	end

	def add_msg_listener(msgName, callableObject = nil, &block)
		return if !@msgNames.has_key? msgName
		
		if !callableObject.nil?
			@msgNames[msgName].push(callableObject)
		elsif !block.nil?
			@msgNames[msgName].push(block)
		else
			raise "you have to define a callback object"
		end
	end

	def del_msg_listener(msgName, object)
		@msgNames[msgName].delete(object) if @msgNames.has_key? msgName
	end

	#######
	private
	#######

	def add_msg_name(msgName)
		name = msgName.id2name
		return if @msgNames.has_key? name
		raise "msgName must begin with upper case letter" if !(('A'..'Z') === name[0..0])

		@msgNames[name.hash] = []
		self.class.class_eval("#{name} = #{name.hash}")
	end

	def del_msg_name(msgName)
		@msgNames.delete(msgName)
	end

	def dispatch_msg(msgName, *args)
		@msgNames[msgName].each {|obj|
			obj.call(*args)
		}
	end

end

if __FILE__ == $0
	
	class Test
		include Listener
		def initialize
			super
			add_msg_name(:Test)
		end

		def dispatch_it(i)
			dispatch_msg(Test, i)
		end
	end
	
	def doit(i)
		p i
	end

	t = Test.new
	t.add_msg_listener(Test::Test, method(:doit))
	t.dispatch_it('hallo')
	p t.inspect
	t.del_msg_listener(Test::Test, method(:doit))
	t.dispatch_it('hallo')
	p t.inspect

end
