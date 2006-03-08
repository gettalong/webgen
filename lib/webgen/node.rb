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

require 'uri'
require 'webgen/composite'

# The Node class is used for building the internal data structure which represents the output tree.
class Node

  include Composite

  # The parent node.
  attr_accessor :parent

  # The path of this node.
  attr_reader   :path

  # Information used for processing the node.
  attr_accessor :node_info

  # Meta information associated with the node.
  attr_accessor :meta_info

  # Initializes a new Node instance.
  #
  # +parent+::
  #    if this parameter is +nil+, then the new node acts as root. Otherwise, +parent+ has to
  #    be a valid node instance.
  # +path+::
  #    The path for this node. If this node is a directory, the path must have a trailing
  #    slash ('dir/'). If it is a fragment, the hash sign must be the first character of the
  #    path ('#fragment'). A compound path like 'dir/file#fragment' is also allowed as are
  #    absolute paths like 'http://myhost.com/'.
  #
  #    Note: a compound path like 'dir/file' is invalid if the parent node already has a child
  #    with path 'dir/'!!! (solution: just create a node with path 'file' and node 'dir/' as parent!)
  def initialize( parent, path )
    @parent = parent
    @path = path
    @node_info = Hash.new
    @meta_info = Hash.new
  end

  # Returns the root node for +node+.
  def self.root( node )
    node = node.parent until node.parent.nil?
    node
  end

  # Gets object +name+ from +meta_info+.
  def []( name )
    @meta_info[name]
  end

  # Assigns +value+ to +meta_info+ called +name.
  def []=( name, value )
    @meta_info[name] = value
  end

  # Returns the full path for this node. This also includes the paths of virtual parent nodes.
  def full_path
    if URI::parse( @path ).absolute?
      @path
    else
      (@parent.nil? ? @path : @parent.full_path + @path)
    end
  end

  # Returns the level of the node. The level specifies how deep the node is in the hierarchy.
  def level
    (@parent.nil? ? 0 : @parent.level + 1)
  end

  # Checks if the node is a directory.
  def is_directory?
    path[-1] == ?/
  end

  # Checks if the node is a file.
  def is_file?
    !is_directory? && !is_fragment?
  end

  # Checks if the node is a fragment.
  def is_fragment?
    path[0] == ?#
  end

  # Returns the route to the given path. The parameter +path+ can be: a String, a Node or an URL.
  def route_to( other )
    url = case other
          when String then self.to_url + other
          when Node then other.to_url
          else raise ArgumentError
          end
    route = self.to_url.route_to( url ).to_s
    (route == '' ? other.path : route )
  end

  # Checks if the current node is in the subtree which is spanned by the supplied node. The check is
  # performed using only the +parent+ information of the involved nodes, NOT the actual path values!
  def in_subtree_of?( node )
    temp = self
    temp = temp.parent while !temp.nil? && temp != node
    !temp.nil?
  end

  # Returns the node representing the given +path+. The path can be absolute or relative to the
  # current node. If no node exists for the given path or it would lie outside the node tree, +nil+
  # is returned.
  def resolve_node( path )
    url = self.to_url + path

    path = url.path[1..-1] + (url.fragment.nil? ? '' : '#' + url.fragment)

    return nil if path =~ /^\.\./ # path outside dest dir

    node = Node.root( self )

    while !node.nil? && !path.empty?
      node = node.find {|c| /^#{c.is_directory? ? c.path[0..-2] : c.path}/ =~ path}
      path.sub!( (node.is_directory? ? /^#{node.path[0..-2]}\/?/ : /^#{node.path}/), '' ) unless node.nil?
      break if path.empty?
    end

    node
  end

  # Returns the full URL (including dummy scheme and host) for use with URI classes.
  def to_url
    url = URI::parse( full_path )
    url = URI::parse( 'webgen://webgen.localhost/' ) + url unless url.absolute?
    url
  end

  # Returns an informative representation of the node.
  def inspect
    "<##{self.class.name}: path=#{full_path}>"
  end

  alias_method :to_s, :full_path

  #######
  private
  #######

  # Delegates missing methods to a processor. The current node is placed into the argument array as
  # the first argument before the method +name+ is invoked on the processor.
  def method_missing( name, *args, &block )
    if @node_info[:processor]
      @node_info[:processor].send( name, *([self] + args), &block )
    else
      super
    end
  end

end
