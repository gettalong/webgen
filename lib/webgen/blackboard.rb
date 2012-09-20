# -*- encoding: utf-8 -*-

module Webgen

  # A blackboard object provides methods for inter-object communication. Objects may register
  # themselves for specific messsage names and get notified when such a message gets dispatched.
  #
  # For a list of all available messages have a look at the Webgen documentation page.
  class Blackboard

    # Create a new Blackboard object.
    def initialize
      @listener = {}
    end

    # Add the given block as listener for the messages +msg_names+ (one message name or an array of
    # message names). If you want to be able to remove the block from being called by the blackboard
    # later, you have to provide a unique ID object!
    def add_listener(msg_names = nil, id = nil, &block)
      if !block.nil?
        [msg_names].flatten.compact.each {|name| (@listener[name] ||= []) << [id, block]}
      else
        raise ArgumentError, "You have to provide a block"
      end
    end

    # Remove the blocks associated with the given ID from the dispatcher queues of the given message
    # names.
    def remove_listener(msg_names, id)
      [msg_names].flatten.each {|name| @listener[name].delete_if {|lid, b| lid == id} if @listener[name]}
    end

    # Dispatch the message +msg_name+ to all listeners for this message, passing the given
    # arguments.
    def dispatch_msg(msg_name, *args)
      return unless @listener[msg_name]
      @listener[msg_name].each {|id, obj| obj.call(*args)}
    end

  end

end
