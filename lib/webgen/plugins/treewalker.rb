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
require 'util/listener'

# All plugins which count as "tree walkers" should be put into this module.
module TreeWalkers

  # This is the main class for tree walkers. A tree walker plugin can register itself with this class
  # so that it is called when the main class' #execute method is called.
  class TreeWalker < UPS::Plugin

    include Listener

    NAME = "Tree Walker"
    SHORT_DESC = "Super plugin for transforming the data tree"


    def initialize
      add_msg_name :preorder
      add_msg_name :postorder
    end


    # Walks the tree and calls all registered plugins for each and every node.
    def execute( tree, level = 0 )
      dispatch_msg :preorder, tree, level
      tree.each do |child|
        execute( child, level + 1 )
      end
      dispatch_msg :postorder, tree, level
    end

  end


  # Prints the whole tree of read files if the log level is at least DEBUG.
  class DebugTreePrinter < UPS::Plugin

    NAME = "Debug Tree Printer"
    SHORT_DESC = "Prints out the information in the tree for debug purposes."


    def init
      UPS::Registry[TreeWalker::NAME].add_msg_listener( :preorder, method( :execute ) )
    end


    def execute( node, level )
      self.logger.debug { "   "*level  << "\\_ "*(level > 0 ? 1 : 0) << (node['virtual'] ? "[V]" : "") << "#{node['title']}: #{node['src']} -> #{node['dest']}" }
    end

  end

  UPS::Registry.instance.register_plugin( TreeWalker )
  UPS::Registry.instance.register_plugin( DebugTreePrinter )

end
