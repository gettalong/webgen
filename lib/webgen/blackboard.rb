module Webgen

  class Blackboard

    def initialize
      @listener = {}
      @services = {}
    end

    # Adds the +callable_object+ or the given block as listener for messages +msg_names+ (one
    # message name or an array of message names).
    def add_listener(msg_names = nil, callable_object = nil, &block)
      callable_object = callable_object || block
      if !callable_object.nil?
        raise ArgumentError, "The listener needs to respond to 'call'" unless callable_object.respond_to?(:call)
        [msg_names].flatten.compact.each {|name| (@listener[name] ||= []) << callable_object}
      else
        raise ArgumentError, "You have to provide a callback object or a block"
      end
    end

    # Remove the given object from the dispatcher queues of the hooks specified in +msg_names+.
    def del_listener(msg_names, callable_object)
      [msg_names].flatten.each {|name| @listener[name].delete(callable_object) if @listener[name]}
    end

    # Dispatch the message +msg_name+ to all listeners for this message, passing the given arguments.
    def dispatch_msg(msg_name, *args)
      return unless @listener[msg_name]
      @listener[msg_name].each {|obj| obj.call(*args)}
    end

    # Add a service named +service_name+ to the blackboard.
    def add_service(service_name, callable_object = nil, &block)
      callable_object = callable_object || block
      if @services.has_key?(service_name)
        raise "The service name '#{service_name}' is already taken"
      else
        raise ArgumentError, "An object providing a service needs to respond to 'call'" unless callable_object.respond_to?(:call)
        @services[service_name] = callable_object
      end
    end

    # Delete the service +service_name+.
    def del_service(service_name)
      @services.delete(service_name)
    end

    # Invoke the service called +service_name+ with the given arguments.
    def invoke(service_name, *args)
      if @services.has_key?(service_name)
        @services[service_name].call(*args)
      else
        raise ArgumentError, "No such service named '#{service_name}' available"
      end
    end

  end

end
