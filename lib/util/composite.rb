#
# Module Composite
#
# Implementation of the Composite pattern.
#
# $Id$
#

# Implements the Composite pattern as mixin.
module Composite

    include Enumerable

    # Returns the array of children
    def children
        @children = [] unless defined? @children
        @children
    end

    # Adds all objects in the array
    def add_children( array )
        if array.kind_of? Array
            @children = [] unless defined? @children
            @children.concat array
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
        @children = [] unless defined? @children
        @children.push child unless @children.include? child
    end

    # Depending on the type of argument one of these actions is taken
    #
    # +Numeric+:: the child at the specified position is deleted
    # +else+:: the specified child is deleted
    def del_child( child )
        if child.kind_of? Numeric
            @children.delete_at child if defined? @children
        else
            @children.delete child if defined? @children
        end
    end

    # Iterates over all childrenldren
    def each   # :yields: child
        children.each do |child| yield child end if defined? @children
    end

    # Checks if there are any children
    def has_children?
        defined?( @children ) && children.length > 0
    end

end
