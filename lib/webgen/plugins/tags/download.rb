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

require 'webgen/plugins/tags/tags'
require 'yaml'
require 'uri'
require 'open-uri'

module Tags

  class DownloadTag < DefaultTag

    summary "Provides a nice download link and, optional, image "
    add_param 'url', nil, 'The URL to the file. Can be a local file or one referenced via HTTP/FTP.'
    add_param 'icon', nil, 'The URL to an icon which will be shown next to the name.'
    add_param 'alwaysShowDownloadIcon', false, 'Specifies if the download icon should always be shown, or only ' \
    'when no icon is available for the file type.'
    add_param 'mappingFile', nil, 'An additional mapping file used for mapping extensions to icons.'
    set_mandatory 'url', true

    depends_on 'Tags', 'ResourceManager'

    CSS = '
.webgen-file-icon, .webgen-download-icon {
  vertical-align: middle;
}
'

    def initialize
      super
      @processOutput = true
      register_tag( 'download' )

      Webgen::Plugin['ResourceManager'].append_data( 'webgen-css', CSS )
      @default_mapping = load_mapping( File.join( Webgen::Configuration.data_dir, 'icon_mapping.yaml' ) )
    end

    def process_tag( tag, node, refNode )
      url = get_param( 'url' )
      return '' if url.nil?

      mapping = @default_mapping.dup
      mapping.update( load_mapping( get_param( 'mappingFile' ) ) ) if File.exists?( get_param( 'mappingFile' ) || '' )

      icon = file_icon( File.extname( url ), mapping, node )
      output = ''
      output << download_icon if get_param( 'alwaysShowDownloadIcon' ) || icon.nil?
      output << icon unless icon.nil?
      output << file_link( url, node, refNode )
      output << file_size( url, refNode )
    end

    #######
    private
    #######

    def download_icon
      "<img class=\"webgen-download-icon\" src=\"{resource: webgen-icons-download}\" alt=\"Download icon\" />"
    end

    def file_icon( ext, mapping, node )
      data = mapping[ext]
      src = get_param( 'icon' )
      if src.nil? && !data.nil?
        if data[0] == :resource
          src = "{resource: #{data[1]}}"
        else
          icon_node = Node.root( node ).node_for_string( data[1] )
          unless icon_node.nil?
            src = node.relpath_to_node( icon_node )
          end
        end
      end
      (src.nil? ? nil : "<img class=\"webgen-file-icon\" src=\"#{src}\" alt=\"File icon\" />")
    end

    def file_link( url, node, refNode )
      link = if URI.parse( url ).absolute?
               url
             else
               fileNode = refNode.node_for_string( url )
               (fileNode.nil? ? '' : node.relpath_to_node( fileNode ))
             end
      "<a href=\"#{link}\">#{File.basename( url )}</a>"
    end

    UNIT_NAMES = ['Byte', 'KiB', 'MiB', 'GiB', 'TiB']

    def file_size( url, refNode )
      size = nil
      catch :size do
        begin
          if URI.parse( url ).absolute?
            open( url, :content_length_proc => proc {|size| throw :size} ) {|f| }
          else
            fileNode = refNode.node_for_string( url )
            size = File.size( fileNode.recursive_value( 'src' ) )
          end
        rescue
        end
      end

      if size.nil?
        logger.warn { "Could not get file size information for file <#{url}>" }
        ''
      else
        size, unit = [size.to_f, 0]
        size, unit = [size / 1024, unit + 1] while size > 1024
        format_str = if unit == 0
                       " (%d %s)"
                     else
                       " (%.2f %s)"
                     end
        format_str % [size, UNIT_NAMES[unit]]
      end
    end

    def load_mapping( file )
      data = YAML::load( File.read( file ) )
      mapping = {}
      if data['resource-mapping']
        data['resource-mapping'].each do |icon, exts|
          exts.each {|ext| mapping[ext] = [:resource, icon]}
        end
      end
      if data['file-mapping']
        data['file-mapping'].each do |icon, exts|
          exts.each {|ext| mapping[ext] = [:file, icon]}
        end
      end
      mapping
    end

  end

end
