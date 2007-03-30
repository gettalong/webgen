#
#--
#
# $Id: listener.rb 271 2005-05-09 08:50:47Z thomas $
#
# webgen: template based static website generator
# Copyright (C) 2004 Thomas Leitner
#
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU
# General Public License as published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program; if not,
# write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#++
#

# Module Listener
#
# Implementation of the listener pattern. The including class defines messages to which other
# classes can listen.
#
# Usage example:
#
#  class Test
#    include Listener
#
#    def initialize
#      add_msg_name :test
#    end
#
#    def invoke( *param )
#      dispatch_msg( :test, *param )
#    end
#
#  end
#
#  t = Test.new
#  t.add_msg_listener( :test ) do |*param|
#    print param.inspect
#  end
#  t.invoke 'hello'
#  t.invoke 'lester', ['tsd', 4, 'test']
#
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
