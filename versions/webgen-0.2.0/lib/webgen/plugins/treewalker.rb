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

require 'util/ups'

# All plugins which count as "tree walkers" should be put into this module.
module TreeWalkers

  # This is the main class for tree walkers. A tree walker plugin can register itself with this class
  # so that it is called when the main class' #execute method is called.
  class TreeWalker < UPS::Plugin


    NAME = "Tree Walker"
    SHORT_DESC = "Super plugin for transforming the data tree"

    attr_reader :walkers

    def initialize
      @walkers = []
    end


    # Uses either all registered walkers or the specified +walker+. Walks the +tree+ for each walker
    # separately.
    def execute( tree, walker = nil )
      walkers = ( walker.nil? ? @walkers : [walker] )
      walkers.each do |walker|
        walk_tree( tree, walker, 0 )
      end
    end

    #######
    private
    #######

    # Walks the tree and calls the plugin +walker+ for each and every node.
    def walk_tree( node, walker, level )
      walker.handle_node( node, level )
      node.each do |child|
        walk_tree( child, walker, level + 1 )
      end
    end

  end


  # Prints the whole tree of read files if the log level is at least DEBUG.
  class DebugTreePrinter < UPS::Plugin

    NAME = "Debug Tree Printer"
    SHORT_DESC = "Prints out the information in the tree for debug purposes."


    def init
      UPS::Registry[TreeWalker::NAME].walkers << self
    end


    def handle_node( node, level )
      self.logger.debug { "   "*level  << "\\_ "*(level > 0 ? 1 : 0) << (node['virtual'] ? "[V]" : "") << "#{node['title']}: #{node['src']} -> #{node['dest']}" }
    end

  end

  UPS::Registry.instance.register_plugin( TreeWalker )
  UPS::Registry.instance.register_plugin( DebugTreePrinter )

end
