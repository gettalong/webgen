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

require 'webgen/plugins/filehandler/filehandler'
require 'webgen/plugins/filehandler/directory'
require 'webgen/plugins/filehandler/pagehandler/page'

module FileHandlers

  class PictureGalleryFileHandler < DefaultHandler

    summary "Handles picture gallery files for page file"
    extension 'gallery'
    add_param "picturesPerPage", 2, 'Number of picture per gallery page'
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
      @path = File.dirname( file )
      images = Dir[File.join( @path, get_param( 'files' ))].collect {|i| i.sub( /#{@path + File::SEPARATOR}/, '' ) }
      self.logger.info { "Creating gallery for file <#{file}> with #{images.length} pictures" }

      create_layouter
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

    def create_layouter
      self.logger.info { "Creating layouter..." }
      @layouter = PictureGalleryLayouter::DefaultLayouter.layouter( get_param( 'layout' ) )
      if @layouter.nil?
        self.logger.error { "Layouter '#{get_param( 'layout' )}' does not exist, using default layouter" }
        @layouter = PictureGalleryLayouter::DefaultLayouter
      end
      @layouter = @layouter.new
    end

    def call_layouter( type, metainfo, *args )
      content = @layouter.send( type.to_s, *args )
      "#{metainfo.to_yaml}\n---\n#{content}"
    end

    def create_gallery( images, parent )
      main = create_main_page( images, parent )
      main['galleries'] = create_gallery_pages( images, parent )

      if main['galleries'].length != 1
        mainNode = Webgen::Plugin['PageHandler'].create_node_from_data( call_layouter( :main, main, main ), main['srcName'], parent )
        parent.add_child( mainNode )
      else
        main['galleries'][0]['title'] = main['title']
        main['galleries'][0]['inMenu'] = main['inMenu']
        main['galleries'][0].update( @filedata['mainPage'] || {} )
      end

      main['galleries'].each_with_index do |gallery, gIndex|
        node = Webgen::Plugin['PageHandler'].create_node_from_data( call_layouter( :gallery, gallery, main, gIndex ), gallery['link'], parent )
        parent.add_child( node )
        gallery['imageList'].each_with_index do |image, iIndex|
          node = Webgen::Plugin['PageHandler'].create_node_from_data( call_layouter( :picture, image, main, gIndex, iIndex ), image['srcName'], parent )
          parent.add_child( node )
        end
      end
    end

    def create_main_page( images, parent )
      main = {}
      main['title'] = get_param( 'title' )
      main['inMenu'] = get_param( 'mainPageInMenu' )
      main['template'] = get_param( 'mainPageTemplate' )
      main['srcName'] = gallery_file_name( main['title'] )
      main['blocks'] = [{'name'=>'content', 'format'=>'html'}]
      main.update( @filedata['mainPage'] || {} )
      main
    end

    def create_gallery_pages( images, parent )
      galleries = []
      picsPerPage = get_param( 'picturesPerPage' )
      0.step( images.length - 1, picsPerPage ) do |i|
        data = (@filedata['galleryPages'] || {}).dup

        data['blocks'] ||= [{'name'=>'content', 'format'=>'html'}]
        data['template'] ||= get_param( 'galleryPageTemplate' )
        data['inMenu'] ||= get_param( 'galleryPageInMenu' )
        data['number'] = i/picsPerPage + 1
        data['title'] = gallery_title( data['number'] )
        data['link'] = gallery_file_name( data['title'] )
        data['imageList'] = create_picture_pages( images[i..(i + picsPerPage - 1)], parent )

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

    def create_picture_pages( images, parent )
      imageList = []
      images.each do |image|
        imageData = (@filedata[image] || {}).dup

        imageData['blocks'] ||= [{'name'=>'content', 'format'=>'html'}]
        imageData['title'] ||= "Picture #{File.basename( image )}"
        imageData['description'] ||= ''
        imageData['inMenu'] ||= get_param( 'picturePageInMenu' )
        imageData['template'] ||= get_param( 'picturePageTemplate' )
        imageData['imageFilename'] = image
        imageData['srcName'] = File.basename( image ).tr( ' .', '_' ) + '.html'
        imageData['thumbnail'] ||= get_thumbnail( imageData, parent )

        imageList << imageData
      end
      imageList
    end

    def get_thumbnail( imageData, parent )
      imageData['imageFilename']
    end

  end

  # Try to use RMagick as thumbnail creator
  begin
    require 'RMagick'

    class PictureGalleryFileHandler

      def get_thumbnail( imageData, parent )
        p_node = Webgen::Plugin['DirHandler'].recursive_create_path( File.dirname( imageData['imageFilename'] ), parent )
        node = Webgen::Plugin['ThumbnailWriter'].create_node( File.join( @path, imageData['imageFilename'] ), p_node )
        p_node.add_child( node )

        File.dirname( imageData['imageFilename'] ) + '/' + node['dest']
      end

    end

    class ThumbnailWriter < DefaultHandler

      summary "Writes out thumbnails with RMagick"
      add_param "thumbnailSize", "100x100", "The size of the thumbnails"

      def create_node( file, parent )
        node = Node.new( parent )
        node['title'] = node['src'] = node['dest'] = 'tn_' + File.basename( file )
        node['tn:imageFile'] = file
        node['processor'] = self
        node
      end

      def write_node( node )
        image = Magick::ImageList.new( node['tn:imageFile'] )
        image.change_geometry( get_param( 'thumbnailSize' ) ) {|c,r,i| i.resize!( c, r )}
        self.logger.info {"Creating thumbnail <#{node.recursive_value('dest')}> from <#{node['tn:imageFile']}>: #{image.inspect}"}
        image.write( node.recursive_value( 'dest' ) )
      end

    end

  rescue LoadError => e
    self.logger.warn { "Could not load RMagick, creation of thumbnails not available" }
  end

end


module PictureGalleryLayouter

  class DefaultLayouter < Webgen::Plugin

    summary "Base class for all Picture Gallery Layouters and default layouter"

    # Holds all layouters
    @@layouter = {}

    # Associates a specific layout name with a layouter.
    def self.layout_name( name )
      @@layouter[name] = self
    end

    layout_name 'default'

    # Returns the layouter called +name+.
    def self.layouter( name )
      @@layouter[name]
    end

    # Returns the thumbnail img tag for the given +image+.
    def thumbnail_tag_for_image( image )
      if image['thumbnail'] != image['imageFilename']
        "<img src='#{image['thumbnail']}' alt='#{image['title']}' />"
      else
        "<img src='#{image['imageFilename']}' width='100' height='100' alt='#{image['title']}'/>"
      end
    end


    # Should be overwritten by subclasses! +data+ is the data structure which holds all information
    # about the gallery.
    def main( data )
      s = "
<h2>#{data['title']}</h2>
<div class=\"webgen-gallery\">
<table>
"
      0.step( data['galleries'].length - 1, 5 ) do |i|
        s += "<tr>"
        s += data['galleries'][i...i+5].collect {|g| "<td><a href=\"#{g['link']}\">#{thumbnail_tag_for_image( g['imageList'][0] )}<br />#{g['title']}</a></td>"}.join( "\n" )
        s += "</tr>"
      end
      s += "</table></div>"
    end

    # Should be overwritten by subclasses! +data+ is the data structure which holds all information
    # about the gallery. +gIndex+ is the index of the current gallery.
    def gallery( data, gIndex )

      s = "
<h2>#{data['title']}</h2>
<div class=\"webgen-gallery\">
<table>
"
      0.step( data['galleries'][gIndex]['imageList'].length - 1, 5 ) do |i|
        s += "<tr>"
        s += data['galleries'][gIndex]['imageList'][i...i+5].collect {|i| "<td><a href=\"#{i['srcName']}\">#{thumbnail_tag_for_image( i )}<br />#{i['title']}</a></td>"}.join( "\n" )
        s += "</tr>"
      end
      s += "</table></div>"
    end

    # Should be overwritten by subclasses! +data+ is the data structure which holds all information
    # about the gallery. +gIndex+ is the index of the current gallery. +iIndex+ is the index of the
    # current image.
    def picture( data, gIndex, iIndex )
      "
<div class=\"webgen-picture\">
<img src='#{data['galleries'][gIndex]['imageList'][iIndex]['imageFilename']}' alt='#{data['galleries'][gIndex]['imageList'][iIndex]['title']}' />
</div>

{description: }
"
    end

  end

end
