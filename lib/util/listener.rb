#
# Module Listener
#
# Implementation of the listener pattern. The including class defines messages to which other
# classes can listen.
#
# $Id$
#

# Implements the listener pattern.
module Listener


    # Adds a new message listener for the object. The message +msgName+
    # will be dispatched to either the given +callableObject+ (has to respond
    # to +call+) or the given block. If both are specified the +callableObject+
    # is used.
    def add_msg_listener( msgName, callableObject = nil, &block )
        return unless defined?( @msgNames ) && @msgNames.has_key?( msgName )

        if !callableObject.nil?
            raise NoMethodError, "listener needs to respond to 'call'" unless callableObject.respond_to? :call
            @msgNames[msgName].push callableObject
        elsif !block.nil?
            @msgNames[msgName].push block
        else
            raise "you have to provide a callback object or a block"
        end
    end


    # Removes the given object from the dispatcher queue of the message +msgName+.
    def del_msg_listener( msgName, object )
        @msgNames[msgName].delete object if defined? @msgNames
    end


    #######
    private
    #######


    # Adds a new message target called +msgName+
    def add_msg_name( msgName )
        @msgNames = {}  unless defined? @msgNames
        @msgNames[msgName] = [] unless @msgNames.has_key? msgName
    end


    # Deletes the message target +msgName+.
    def del_msg_name( msgName )
        @msgNames.delete msgName if defined? @msgNames
    end


    # Dispatches the message +msgName+ to all listeners for this message,
    # providing the given arguments
    def dispatch_msg( msgName, *args )
        if defined? @msgNames and @msgNames.has_key? msgName
            @msgNames[msgName].each do |obj|
                obj.call( *args )
            end
        end
    end

end
