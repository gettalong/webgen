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
require 'webgen/plugins/filehandler/pagehandler/page'

module FileHandlers

  class PictureGalleryFileHandler < DefaultHandler

    summary "Handles picture gallery files for page file"
    extension 'gallery'
    add_param "picturesPerPage", 20, 'Number of picture per gallery page'
    add_param "picturePageInMenu", false, 'True if the picture pages should be in the menu'
    add_param "galleryPageInMenu", false, 'True if the gallery pages should be in the menu'
    add_param "mainPageInMenu", true, 'True if the main page of the picture gallery should be in the menu'
    add_param "galleryPageTemplate", nil, 'The template for gallery pages. If nil or a not existing file is specified, the default template is used.'
    add_param "picturePageTemplate", nil, 'The template for picture pages. If nil or a not existing file is specified, the default template is used.'
    add_param "mainPageTemplate", nil, 'The template for the main page. If nil or a not existing file is specified, the default template is used.'
    add_param "files", 'images/**/*.jpg', 'The Dir glob for specifying the picture files'
    add_param "title", 'Gallery', 'The title of the gallery'
    add_param "layout", 'default', 'The layout used'

    depends_on 'FileHandler', 'PageHandler'

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

      create_gallery( images, parent )

      nil
    end

    def write_node( node )
      # do nothing
    end

    #######
    private
    #######

    # Method overridden to lookup parameters specified in the gallery file first.
    def get_param( name )
      ( @filedata.has_key?( name ) ? @filedata[name] : super )
    end

    def call_layouter( type, data )
      content = self.send( type.to_s + "_page_" + get_param( 'layout' ), data )
      "#{data.to_yaml}\n---\n#{content}"
    end

    def create_gallery( images, parent )
      nr_gallery_pages = (Float(images.length) / get_param( 'picturesPerPage' ) ).ceil
      main = create_main_page( images )
      main['galleries'] = create_gallery_pages( images )

      if nr_gallery_pages != 1
        mainNode = Webgen::Plugin['PageHandler'].create_node_from_data( call_layouter( :main, main ), main['srcName'], parent )
        parent.add_child( mainNode )
      else
        main['galleries'][0]['title'] = main['title']
        main['galleries'][0]['inMenu'] = main['inMenu']
        main['galleries'][0].update( @filedata['mainPage'] || {} )
      end

      main['galleries'].each do |gallery|
        node = Webgen::Plugin['PageHandler'].create_node_from_data( call_layouter( :gallery, gallery ), gallery['link'], parent )
        parent.add_child( node )
        gallery['imageList'].each do |image|
          node = Webgen::Plugin['PageHandler'].create_node_from_data( call_layouter( :picture, image ), image['srcName'], parent )
          parent.add_child( node )
        end
      end
    end

    def create_main_page( images )
      main = {}
      main['title'] = get_param( 'title' )
      main['inMenu'] = get_param( 'mainPageInMenu' )
      main['template'] = get_param( 'mainPageTemplate' )
      main['srcName'] = gallery_file_name( main['title'] )
      main.update( @filedata['mainPage'] || {} )
      main
    end

    def create_gallery_pages( images )
      galleries = []
      picsPerPage = get_param( 'picturesPerPage' )
      0.step( images.length - 1, picsPerPage ) do |i|
        data = Hash.new

        data['template'] = get_param( 'galleryPageTemplate' )
        data['inMenu'] = get_param( 'galleryPageInMenu' )
        data['number'] = i/picsPerPage + 1
        data['title'] = gallery_title( data['number'] )
        data['link'] = gallery_file_name( data['title'] )
        data['prevGalleryNumber'] = ( i == 0 ? nil : data['number'] - 1 )
        data['prevGalleryTitle'] = gallery_title( data['prevGalleryNumber'] )
        data['prevGalleryLink'] = gallery_file_name( data['prevGalleryTitle'] )
        data['nextGalleryNumber']= ( images.length <= i + picsPerPage ? nil : data['number'] + 1 )
        data['nextGalleryTitle'] = gallery_title( data['nextGalleryNumber'] )
        data['nextGalleryLink'] = gallery_file_name( data['nextGalleryTitle'] )
        data['images'] = images[i..(i + picsPerPage - 1)]
        data['imageList'] = create_picture_pages( data['images'] )

        galleries << data
      end
      galleries
    end

    def gallery_title( index )
      ( index.nil? ? nil : get_param( 'title' ) + ' ' + index.to_s )
    end

    def gallery_file_name( title )
      ( title.nil? ? nil : title.tr( ' .', '_' ) + '.html' )
    end

    def create_picture_pages( images )
      imageList = []
      images.each do |image|
        imageData = @filedata[image] || {}

        imageData['title'] ||= "Picture #{File.basename( image )}"
        imageData['description'] ||= ''
        imageData['inMenu'] = get_param( 'picturePageInMenu' )
        imageData['template'] = get_param( 'picturePageTemplate' )
        imageData['imageFilename'] = image
        imageData['srcName'] = File.basename( image ).tr( ' .', '_' ) + '.html'

        imageList << imageData
      end
      imageList
    end

    def main_page_default( data )
      "
#{data['galleries'].collect {|g| "<img src='#{g['images'][0]}' width='100' height='100' alt='#{g['title']}' /> \"#{g['title']}\":#{g['link']}"}.join( "\n\n" )}
"
    end

    def gallery_page_default( data )
      "
<div class=\"webgen-gallery\">

#{data['imageList'].collect {|i| "<img src='#{i['imageFilename']}' width='100' height='100' alt='#{i['title']}'/> \"#{i['title']}\":#{i['srcName']}" }.join( "\n\n" )}

</div>
"
    end

    def picture_page_default( data )
      "
<div class=\"webgen-picture\">

<img src='#{data['imageFilename']}' alt='#{data['title']}' />

</div>

{description: }
"
    end

  end

end
