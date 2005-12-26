#
#--
#
# $Id$
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


# Module Composite
#
# Implementation of the Composite pattern.
#
# Usage example:
#
#  class Test
#    include Composite
#  end
#
#  t = Test.new
#  t.add_child("Hello")
#  t.add_child("Lester")
#  t.each do |child| print child end
#


module Composite

  include Enumerable


  # Returns the array of children
  def children
    @children = [] unless defined?( @children )
    @children
  end


  # Adds all objects in the array
  def add_children( array )
    if array.kind_of?( Array )
      @children = [] unless defined?( @children )
      @children.concat( array )
    else
      raise ArgumentError, "Parameter must be array"
    end
  end


  # Deletes all children
  def del_children
    @children = []
  end


  # Adds the child
  def add_child( child )
    @children = [] unless defined?( @children )
    @children.push( child ) unless @children.include?( child )
  end


  # Depending on the type of argument one of these actions is taken
  #
  # [+Numeric+] the child at the specified position is deleted
  # [+else+]    the specified child is deleted
  def del_child( child )
    if child.kind_of?( Numeric )
      @children.delete_at( child ) if defined?( @children )
    else
      @children.delete( child ) if defined?( @children )
    end
  end


  # Iterates over all childrenldren
  def each   # :yields: child
    children.each {|child| yield child } if defined?( @children )
  end


  # Checks if there are any children
  def has_children?
    defined?( @children ) && children.length > 0
  end

end
