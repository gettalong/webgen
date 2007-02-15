#
#--
#
# $Id: gallery.rb 569 2006-12-29 20:11:21Z thomas $
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

require 'yaml'
require 'erb'
require 'webgen/sipttra_format'

load_plugin 'webgen/plugins/filehandlers/filehandler'
load_plugin 'webgen/plugins/filehandlers/page'


module FileHandlers

  # Handles sipttra (Simple Plain Text Tracker) files.
  class SipttraHandler < DefaultHandler

    infos( :name => 'File/SipttraHandler',
           :author => Webgen::AUTHOR,
           :summary => "Handles sipttra (Simple Plain Text Tracker) files"
           )

    register_extension 'todo'

    default_meta_info( 'template' => '/sipttra.template' )

    def create_node( file, parent, meta_info )
      begin
        data = File.read( file )
        s = Sipttra::Tracker.new( data )
      rescue
        log(:error) { "Could not parse sipttra file <#{file}>, not creating an output page: #{$!.message}" }
        return
      end
      meta_info.update( s.info['webgen-metainfo'] || {} )

      filename = File.basename( file, '.todo' ) + '.page'
      filehandler = @plugin_manager['Core/FileHandler']
      pagehandler = @plugin_manager['File/PageHandler']
      node = filehandler.create_node( filename, parent, pagehandler ) do |filename, parent, handler, mi|
        pagehandler.create_node_from_data( filename, parent, "Forgotten to specify a sipttra template?! ;-)", mi.merge( meta_info ) )
      end
      node.node_info[:sipttra] = s if node
      node.node_info[:src] = file if node

      node
    end

    def write_node( node )
      # do nothing
    end

  end

end
