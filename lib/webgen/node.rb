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

require 'webgen/logging'
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
    if value.nil?
      value = ''
      self.logger.warn { "No meta information called '#{name}' for <#{metainfo['src']}>" }
    end
    @parent.nil? ? value : @parent.recursive_value( name, ignoreVirtual ) + value
  end


  # Return the relative path from this node to the destNode, virtual nodes are not used in the
  # calculation. The destNode can be any non virtual node. If +destNode+ starts with http://, the
  # relative path to it is the empty string. If +includeDestNode+ is true, then the path of the
  # destination node is appended to the calculated path.
  def relpath_to_node( destNode, includeDestNode = true)
    if destNode['dest'] =~ /^http:\/\//
      path = ''
    else
      from = recursive_value( 'dest' ).sub( /#{self['dest']}$/, '' ).split( '/' )[1..-1] || []
      to = destNode.recursive_value( 'dest' ).sub( /#{destNode['dest']}$/, '' ).split( '/' )[1..-1] || []

      while from.size > 0 and to.size > 0 and from[0] == to[0]
        from.shift
        to.shift
      end

      from.fill( '..' )
      from.concat( to )
      path = ( from.length == 0 ? '.' : from.join( '/' ) )
      path += '/' + destNode['dest'] if includeDestNode && !destNode.parent.nil?
    end
    path
  end


  # Return the node identified by +destString+ relative to the current node.
  def node_for_string( destString )
    node = get_node_for_string( destString )
    if node.nil?
      self.logger.warn { "Could not get destination node '#{destString}' for <#{metainfo['src']}>" }
    end
    node
  end

  # Check if there is a node for +destString+.
  def node_for_string?( destString )
    get_node_for_string( destString ) != nil
  end

  # Return the level of the node. The level specifies how deep the node is in the hierarchy.
  def level( ignoreVirtual = true )
    if self.parent.nil?
      1
    else
      self.parent.level( ignoreVirtual ) \
      + ( (@metainfo['virtual'] && ignoreVirtual) || (@metainfo['dest'] !~ /\/$/) ? 0 : 1 )
    end
  end

  # Checks if the current node is in the subtree in which the supplied node is. This is done by
  # analyzing the paths of the two nodes.
  def in_subtree?( node )
    node = node.parent if node.metainfo['dest'] !~ /\/$/
    node = node.parent while node['virtual']
    /^#{node.recursive_value( 'dest' )}/ =~ recursive_value( 'dest' )
  end

  # Returns the parent directory for this node. This function ignores virtual directories.
  def parent_dir
    node = self.parent
    node = node.parent while !node.nil? && node['virtual']
    node
  end

  # Returns the root node for +node+.
  def self.root( node )
    node = node.parent until node.parent.nil?
    node
  end

  #######
  private
  #######

  def get_node_for_string( destString )
    if /^\// =~ destString
      node = Node.root( self )
      destString = destString[1..-1]
    else
      node = self.parent_dir || self
    end

    destString.split( '/' ).each do |element|
      return nil if node.nil?
      case element
      when '..' then node = node.parent
      else node = node.find do |child| /^#{element}\/?$/ =~ child['dest'] end
      end
    end

    node
  end

end
