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

require 'webgen/plugins/fileHandler/fileHandler'

module FileHandlers

  class PageFileBacking < DefaultHandler

    NAME = "PageFileBacking"
    SHORT_DESC = "Handles backing files for page file"


    def init
      @backingFile = UPS::Registry['Configuration'].get_config_value( NAME, 'backingFile', 'metainfo.backing' )
      UPS::Registry['File Handler'].extensions['backing'] = self
      UPS::Registry['File Handler'].add_msg_listener( :AFTER_DIR_READ, method( :process_backing_file ) )
    end


    def create_node( path, parent )
      node = Node.new parent
      node['virtual'] = true
      node['src'] = node['dest'] = node['title'] = File.basename( path )
      node['content'] = YAML::load( File.new( path ) )
      node
    end


    def write_node( node )
      # nothing to write
    end


    #######
    private
    #######


    def process_backing_file( dirNode )
      backingFile = dirNode.find do |child| child['src'] == @backingFile end
      return if backingFile.nil?

      backingFile['content'].each do |filename, data|
        backedFile = dirNode.find do |child| child['title'] == filename end
        if backedFile
          data.each do |language, fileData|
            langFile = UPS::Registry['Page Plugin'].get_lang_node( backedFile, language )
            next unless langFile['lang'] == language

            self.logger.info { "Setting meta info data on file <#{langFile.recursive_value( 'dest' )}>" }
            langFile.metainfo.update fileData
          end
        end
      end
    end

  end

  UPS::Registry.register_plugin PageFileBacking

end
