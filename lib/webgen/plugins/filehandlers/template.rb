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

require 'webgen/plugins/filehandlers/page'

module FileHandlers

  # Handles template files. Template files are just page files with another extension.
  class TemplateFileHandler < DefaultFileHandler

    infos :summary =>  "Handles the template files"
    param 'defaultTemplate', 'default.template', 'The default file name for the template file.'

    register_extension 'template'

=begin
TODO: MOVE TO DOC
- use meta_info 'template'
=end

    def create_node( srcName, parent, meta_info )
      begin
        page_meta_info = @plugin_manager['FileHandlers::FileHandler'].meta_info_for( @plugin_manager['FileHandlers::PageFileHandler'] )
        data = WebPageData.new( File.read( srcName ), @plugin_manager['ContentConverters::DefaultContentConverter'].registered_handlers,
                                page_meta_info.merge( meta_info ) )
      rescue WebPageDataInvalid => e
        log(:error) { "Invalid template file <#{srcName}>: #{e.message}" }
        return nil
      end

      if node = parent.find {|n| n =~ srcName }
        log(:warn) { "Can't create node <#{node.full_path}> as it already exists! Using existing!" }
      else
        basename = File.basename( srcName )
        node = FileHandlers::PageFileHandler::PageNode.new( parent, basename, data  )
        node['title'] = 'template'
        node.node_info[:src] = srcName
        node.node_info[:processor] = self
        node.node_info[:pagename] = basename
        node.node_info[:local_pagename] = basename
      end

      node
    end

    def write_node( node )
      # do not write anything
    end

    # Returns the template chain for +node+.
    def templates_for_node( node )
      if node['template'].kind_of?( String )
        template_node = node.resolve_node( node['template'] )
        if template_node.nil?
          log(:warn) { "Specified template '#{node['template']}' for file <#{node.node_info[:src]}> not found, using default template!" }
          template_node = get_default_template( node.parent )
        end
        node['template'] = template_node
      elsif node['template'].kind_of?( Node )
        template_node = node['template']
      else
        log(:info) { "Using default template for <#{node.node_info[:src]}>" }
        template_node = get_default_template( node.parent )
        node['template'] = template_node
      end

      if template_node.nil?
        []
      else
        (template_node == node ? [] : templates_for_node( template_node ) + [template_node])
      end
    end

    #######
    private
    #######

    # Returns the default template of the directory node +dir+. If the template node is not found,
    # the parent directories are searched.
    def get_default_template( dir )
      template_node = dir.find {|child| child =~ param( 'defaultTemplate' ) }
      if template_node.nil?
        if dir.parent.nil?
          log(:warn) { "No default template '#{param( 'defaultTemplate' )}' in root directory found!" }
        else
          template_node = get_default_template( dir.parent )
        end
      end
      template_node
    end

  end

end
