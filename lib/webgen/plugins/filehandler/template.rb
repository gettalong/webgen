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
require 'webgen/plugins/treewalker'

module FileHandlers

  # Handles template files. Template files are generic files which normally specify the layout.
  class TemplatePlugin < DefaultHandler

    plugin "Template File Handler"
    summary "Represents the template files for the page generation in the tree"
    add_param 'defaultTemplate', 'default.template', 'The default file name for the template file.'

    EXTENSION = 'template'


    def init
      Plugin['File Handler'].add_msg_listener( :AFTER_DIR_READ, method( :add_template_to_node ) )
    end


    def create_node( srcName, parent )
      relName = File.basename srcName
      node = Node.new parent
      node['title'] = 'Template'
      node['src'] = node['dest'] = relName
      File.open( srcName ) { |file| node['content'] = file.read }
      return node
    end


    def write_node( node )
      # do not write anything
    end


    def get_template_for_node( node )
      raise "Template file for node not found -> this should not happen!" if node.nil?
      if node.metainfo.has_key? 'template'
        return node['template']
      else
        return get_template_for_node( node.parent )
      end
    end


    #######
    private
    #######

    def add_template_to_node( node )
      templateNode = node.find { |child| child['src'] == get_config_param( 'defaultTemplate' ) }
      if !templateNode.nil?
        node['template'] = templateNode
      elsif node.parent.nil? # dir is root directory
        self.logger.error { "Template file #{get_config_param( 'defaultTemplate' )} in root directory not found, adding dummy template!" }
        templateNode = create_dummy_template node
        node.add_child templateNode
        node['template'] = templateNode
      end
    end

    def create_dummy_template( parent )
      templateNode = Node.new parent
      templateNode['title'] = 'Template'
      templateNode['src'] = templateNode['dest'] = get_config_param( 'defaultTemplate' )
      templateNode['content'] = "<h1>DUMMY TEMPLATE</h1> {content: }"
      templateNode['processor'] = Plugin[TemplatePlugin::NAME]
      templateNode
    end

  end

end


module TreeWalkers

  # Substitutes all occurences of the +template+ meta information with the correct node.
  class TemplateTreeWalker < Webgen::Plugin

    plugin "Template Tree Walker"
    summary "Substitutes all 'template' infos with the approriate node"

    def init
      Plugin['Tree Walker'].walkers << self
    end


    def handle_node( node, level )
      if node.metainfo.has_key?( "template" ) && node['template'].kind_of?( String )
        templateNode = node.get_node_for_string( node['template'] )
        if templateNode.nil?
          self.logger.warn { "Specified template for file <#{node['src']}> not found, using default template!" }
          node.metainfo.delete "template"
        else
          node['template'] = templateNode
          self.logger.info { "Replacing 'template' in <#{node['src']}> with <#{templateNode['src']}>" }
        end
      end
    end

  end

end
