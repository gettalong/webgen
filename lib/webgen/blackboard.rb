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

    # Add the given block as listener for the message +msg_name+.
    #
    # The +id+ parameter can be used to specify a string which uniquely identifies the listener.
    #
    # The +position+ parameter can be used to specify where the listener should be added. The keys
    # :before and :after are recognized and must contain a valid listener ID. If no key is or an
    # unknown ID is specified, the listener is added as last entry in the listener array.
    def add_listener(msg_name, id = nil, position = {}, &block)
      position = if position[:before]
                   (@listener[msg_name] || []).index {|lid, obj| lid == position[:before]}
                 elsif position[:after]
                   (pos = (@listener[msg_name] || []).index {|lid, obj| lid == position[:after]}) && pos + 1
                 end
      insert_listener_at_position(msg_name, id, position || -1, &block)
    end

    # Insert the block as listener for +msg_name+ with the given +id+ at the +position+ in the
    # listener array.
    def insert_listener_at_position(msg_name, id, position, &block)
      if !block.nil?
        (@listener[msg_name] ||= []).insert(position, [id, block])
      else
        raise ArgumentError, "You have to provide a block"
      end
    end
    private :insert_listener_at_position

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
