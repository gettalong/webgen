#
#--
#
# $Id$
#
# webgen: a template based web page generator
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

require 'util/composite'

class Node

  include Composite

  attr_reader   :parent
  attr_accessor :metainfo

  def initialize( parent )
    @parent = parent
    @metainfo = Hash.new
  end

  # Get object +name+ from +metainfo+.
  def []( name )
    @metainfo[name]
  end

  # Assign +value+ to +metainfo+ called +name.
  def []=( name, value )
    @metainfo[name] = value
  end

  # Get the recursive value for metainfo +name+. +ignoreVirtual+ specifies if virtual nodes should
  # not be appended, but they are traversed nonetheless.
  def recursive_value( name, ignoreVirtual = true )
    value = ignoreVirtual && @metainfo['virtual'] ? '' : @metainfo[name]
    @parent.nil? ? value : @parent.recursive_value( name ) + value
  end


  # Returns the relative path from this node to the destNode. The current node
  # is normally a page file node, but the method should work for other nodes
  # too. The destNode can be any non virtual node.
  def get_relpath_to_node( destNode )
    if destNode['external']
      path = ''
    else
      from = @parent.recursive_value( 'dest' ).split( File::SEPARATOR )
      to = destNode.parent.recursive_value( 'dest' ).split( File::SEPARATOR )

      while from.size > 0 and to.size > 0 and from[0] == to[0]
        from.shift
        to.shift
      end

      from.fill( '..' )
      from.concat( to )
      path = from.join( '/' ) + ( from.size > 0 ? '/' : '' )
    end
    path
  end


  # Returns the node identified by +destString+ relative to the current node.
  def get_node_for_string( destString, fieldname = 'dest' )
    if /^#{File::SEPARATOR}/ =~ destString
      node = Node.root self
      destString = destString[1..-1]
    else
      node = self
      node = node.parent until node.kind_of? FileHandlers::DirHandler::DirNode
    end

    destString.split( File::SEPARATOR ).each do |element|
      case element
      when '..'
        node = node.parent
      else
        node = node.find do |child| /^#{element}#{File::SEPARATOR}?$/ =~ child[fieldname] end
      end
      if node.nil?
        self.logger.warn { "Could not get destination node '#{destString}' for <#{metainfo['src']}>, searching field #{fieldname}" }
        return
      end
    end

    return node
  end

  # Returns the level of the node. The level specifies how deep the node is in the hierarchy.
  def level( ignoreVirtual = true )
    recursive_value( 'dest', ignoreVirtual ).count( File::SEPARATOR )
  end

  # Checks if the current node is in the subtree in which the supplied node is. This is done by
  # analyzing the paths of the two nodes.
  def in_subtree?( node )
    /^#{recursive_value( 'dest' )}/ =~ node.recursive_value( 'dest' )
  end

  # Returns the root node for +node+.
  def Node.root( node )
    node = node.parent until node.parent.nil?
    node
  end

end
