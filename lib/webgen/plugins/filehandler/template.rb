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

require 'webgen/plugins/filehandler/filehandler'

module FileHandlers

  # Handles template files. Template files are generic files which specify the layout.
  class TemplatePlugin < DefaultHandler

    plugin "TemplateFileHandler"
    summary "Represents the template files for the page generation in the tree"
    add_param 'defaultTemplate', 'default.template', 'The default file name for the template file.'
    depends_on 'FileHandler'

    def initialize
      extension( 'template', TemplatePlugin )
    end

    def create_node( srcName, parent )
      node = Node.new( parent )
      node['title'] = 'Template'
      node['src'] = node['dest'] = File.basename( srcName )
      File.open( srcName ) { |file| node['content'] = file.read }
      return node
    end

    def write_node( node )
      # do not write anything
    end

    # Return the template for +node+.
    def get_template_for_node( node )
      return get_template( node ) || get_default_template( node )
    end

    #######
    private
    #######

    def get_template( node )
      if node.metainfo.has_key?( "template" ) && node['template'].kind_of?( String )
        templateNode = node.node_for_string( node['template'] )
        if templateNode.nil?
          self.logger.warn { "Specified template for file <#{node.recursive_value('src')}> not found, using default template!" }
        end
        return templateNode
      end
    end

    # Return the default template for +node+. If the template node is not found in the directory of
    # the node, the parent directories are searched.
    def get_default_template( node )
      node = node.parent until node.kind_of?( FileHandlers::DirHandler::DirNode )
      templateNode = node.find { |child| child['src'] == get_param( 'defaultTemplate' ) }
      if templateNode.nil?
        if node.parent.nil?
          self.logger.error { "Template file #{get_param( 'defaultTemplate' )} in root directory not found, aborting!" }
          raise
        else
          return get_default_template( node.parent )
        end
      else
        return templateNode
      end
    end

  end

end
