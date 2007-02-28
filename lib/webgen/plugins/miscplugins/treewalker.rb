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


# All plugins which count as "tree walkers" should be put into this module.
module TreeWalkers

  # This is the main class for tree walkers. A tree walker plugin can register itself with this class
  # so that it is called when the main class' #execute method is called.
  class TreeWalker < Webgen::Plugin

    infos( :name => 'Misc/TreeWalker',
           :author => Webgen::AUTHOR,
           :summary => "Super plugin for traversing the node tree"
           )

    attr_reader :walkers

    def initialize( plugin_manager )
      super
      @walkers = []
    end

    # Walks the +tree+ for the +walker+ in the +direction+, either +:forward+ or +:backward+.
    # If +walker+ is +nil+, then all registered walkers are used!
    def execute( tree, walker = nil, direction = :forward )
      walkers = ( walker.nil? ? @walkers : [walker] )
      walkers.each do |walker|
        walk_tree( tree, walker, 0, direction )
      end
    end

    #######
    private
    #######

    # Walks the tree and calls the plugin +walker+ for each and every node.
    def walk_tree( node, walker, level, direction = :forward )
      walker.call( node, level ) if direction == :forward
      node.each do |child|
        walk_tree( child, walker, level + 1, direction )
      end
      walker.call( node, level ) if direction == :backward
    end

  end


  # Prints the whole tree of read files if the log level is at least DEBUG.
  class DebugTreePrinter < Webgen::Plugin

    infos( :name => 'Misc/DebugTreePrinter',
           :author => Webgen::AUTHOR,
           :summary => "Prints out the information in the tree for debug purposes."
           )

    depends_on 'Misc/TreeWalker'

    def initialize( plugin_manager )
      super
      @plugin_manager['Misc/TreeWalker'].walkers << self
    end

    def call( node, level )
      log(:debug) do
        "   "*level  << "\\_ "*(level > 0 ? 1 : 0) << "#{node['title']}: #{node.node_info[:src]} -> #{node.path}"
      end
    end

  end

end
