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

require 'webgen/plugins/filehandlers/filehandler'

module FileHandlers

  # Handles template files. Template files are generic files which specify the layout.
  class TemplateFileHandler < DefaultFileHandler

    summary "Represents the template files for the page generation in the tree"
    extension 'template'
    add_param 'defaultTemplate', 'default.template', 'The default file name for the template file.'
    depends_on 'FileHandler'

    used_meta_info 'template'

    def create_node( srcName, parent )
      node = Node.new( parent )
      node['title'] = 'Template'
      node['src'] = node['dest'] = File.basename( srcName )
      node['processor'] = self
      File.open( srcName ) { |file| node['content'] = file.read }
      node
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
      if node['template'].kind_of?( String ) && node['template'] != ''
        templateNode = node.node_for_string( node['template'] )
        if templateNode.nil?
          self.logger.warn { "Specified template for file <#{node.recursive_value('src')}> not found, using default template!" }
        end
        node['template'] = templateNode unless templateNode.nil?
        return templateNode
      end
    end

    # Return the default template for +node+. If the template node is not found in the directory of
    # the node, the parent directories are searched.
    def get_default_template( node )
      node = node.parent until node['int:directory?']
      templateNode = node.find { |child| child['src'] == get_param( 'defaultTemplate' ) }
      if templateNode.nil?
        if node.parent.nil?
          self.logger.error { "Template file #{get_param( 'defaultTemplate' )} in root directory not found, creating dummy!" }
          templateNode = DummyTemplateNode.new( node )
          node.add_child( templateNode )
        else
          templateNode = get_default_template( node.parent )
        end
      end
      templateNode
    end

  end

  class DummyTemplateNode < Node

    def initialize( parent )
      super( parent )
      self['src'] = self['dest'] = self['title'] = Webgen::Plugin['TemplateFileHandler']['defaultTemplate']
      self['processor'] = Webgen::Plugin['TemplateFileHandler']
      self['content'] = ''
    end

  end

end
