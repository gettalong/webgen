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
require 'webgen/plugins/filehandler/directory'
require 'webgen/plugins/filehandler/page'

module FileHandlers

  class PictureGalleryFileHandler < DefaultHandler

    plugin "PictureGalleryFileHandler"
    summary "Handles picture gallery files for page file"
    extension 'gallery'
    add_param "picturesPerPage", 20, 'Number of picture per gallery page'
    add_param "picturePageInMenu", false, 'True if the picture pages should be in the menu'
    add_param "galleryPageInMenu", true, 'True if the gallery pages should be in the menu'
    add_param "galleryTemplate", nil, 'The template for gallery pages. If nil or a not existing file is specified, the default template is used.'
    add_param "pictureTemplate", nil, 'The template for picture pages. If nil or a not existing file is specified, the default template is used.'
    add_param "files", 'images/**/*.jpg', 'The Dir glob for specifying the picture files'
    add_param "title", 'Gallery', 'The title of the gallery'

    depends_on 'FileHandler'

    def initialize
      extension( Webgen::Plugin.config[self.class.name].extension, PictureGalleryFileHandler )
    end

    def create_node( file, parent )
      begin
        @filedata = YAML::load( File.read( file ) )
      rescue
        self.logger.error { "Could not parse gallery file <#{file}>, not creating gallery pages" }
        return
      end

      path = File.dirname( file )
      images = Dir[File.join( path, get_param( 'files' ))].collect {|i| i.sub( /#{path + File::SEPARATOR}/, '' ) }
      self.logger.info { "Creating gallery for file <#{file}> with #{images.length} pictures" }

      create_gallery_pages( images, parent )

      nil
    end

    def write_node( node )
      # do nothing
    end

    #######
    private
    #######

    # Override method to lookup parameters specified in the gallery file first.
    def get_param( name )
      ( @filedata.has_key?( name ) ? @filedata[name] : super )
    end

    def create_gallery_pages( images, parent )
      picsPerPage = get_param( 'picturesPerPage' )
      0.step( images.length, picsPerPage ) do |i|
        data = OpenStruct.new

        data.number = i/picsPerPage + 1
        data.title = gallery_title( data.number )
        data.link = gallery_file_name( data.title )
        data.prevGalleryNumber = ( i == 0 ? nil : data.number - 1 )
        data.prevGalleryTitle = gallery_title( data.prevGalleryNumber )
        data.prevGalleryLink = gallery_file_name( data.prevGalleryTitle )
        data.nextGalleryNumber = ( images.length <= i + picsPerPage ? nil : data.number + 1 )
        data.nextGalleryTitle = gallery_title( data.nextGalleryNumber )
        data.nextGalleryLink = gallery_file_name( data.nextGalleryTitle )

        data.images = images[i..(i + picsPerPage - 1)]

        node = Webgen::Plugin['PageHandler'].create_node_from_data( gallery_page_content( data ), data.link, parent )
        parent.add_child( node )

        create_picture_pages( data.images, parent )
      end
    end

    def create_picture_pages( images, parent )
      images.each do |image|
        imageData = OpenStruct.new
        imageData.title = ( @filedata[image].nil? ? "Picture #{File.basename( image )}" : @filedata[image]['title'] )
        imageData.filename = image
        imageData.srcName = File.basename( image, '.*' ).tr( ' .', '_' ) + '.html'
        imageData.description = ( @filedata[image].nil? ? '' : @filedata[image]['desc'] )
        node = Webgen::Plugin['PageHandler'].create_node_from_data( picture_page_content( imageData ), imageData.srcName, parent )
        parent.add_child( node )
      end
    end

    def gallery_title( index )
      ( index.nil? ? nil : get_param( 'title' ) + ' ' + index.to_s )
    end

    def gallery_file_name( title )
      ( title.nil? ? nil : title.tr( ' .', '_' ) + '.html' )
    end

    def gallery_page_content( data )
      "---
inMenu: #{get_param( 'galleryPageInMenu' )}
template: #{get_param( 'galleryTemplate' )}
---
<div class=\"webgen-gallery\">
#{data.filenames.collect {|i| "!#{i}!:#{File.basename( i, '.*' ).tr( ' .', '_' ) + '.html'}" }.join( "\n\n" )}
</div>
"
    end

    def picture_page_content( data )
      "---
inMenu: #{get_param( 'picturePageInMenu' )}
template: #{get_param( 'pictureTemplate' )}
---
<div class=\"webgen-picture\">
!#{data.filename}(#{data.title})!
</div>

#{data.description}
"
    end

  end

end
