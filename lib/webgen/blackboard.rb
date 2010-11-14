# -*- encoding: utf-8 -*-

module Webgen

  # A blackboard object provides methods for inter-object communication. Objects may register
  # themselves for specific messsage names and get notified when such a message gets dispatched.
  #
  # For a list of all available messages have a look at the main Webgen documentation page.
  class Blackboard

    # Create a new Blackboard object.
    def initialize
      @listener = {}
    end

    # Add the +callable_object+ or the given block as listener for the messages +msg_names+ (one
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

    # Remove the given object from the dispatcher queues of the message names specified in
    # +msg_names+.
    def remove_listener(msg_names, callable_object)
      [msg_names].flatten.each {|name| @listener[name].delete(callable_object) if @listener[name]}
    end

    # Dispatch the message +msg_name+ to all listeners for this message, passing the given
    # arguments.
    def dispatch_msg(msg_name, *args)
      return unless @listener[msg_name]
      @listener[msg_name].each {|obj| obj.call(*args)}
    end

  end

end
