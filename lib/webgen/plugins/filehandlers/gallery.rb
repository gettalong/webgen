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
require 'webgen/plugins/filehandlers/directory'
require 'webgen/plugins/filehandlers/page'

module FileHandlers

  class GalleryFileHandler < DefaultFileHandler

    class GalleryInfo

      class Gallery

        attr_accessor :pagename
        attr_reader :title
        attr_reader :data
        attr_reader :images

        def initialize( pagename, images, data )
          @images = images
          @pagename = pagename
          @title = data['title']
          @data = data
        end

        def []( key )
          @data[key]
        end

        def []=( key, value )
          @data[key] = value
        end

        def thumbnail
          @images.first.thumbnail
        end

      end

      class Image

        attr_accessor :pagename
        attr_reader :filename
        attr_reader :title
        attr_reader :data

        def initialize( pagename, filename, data )
          @pagename = pagename
          @filename = filename
          @title = data['title']
          @data = data
        end

        def []( key )
          @data[key]
        end

        def []=( key, value )
          @data[key] = value
        end

        # Returns the thumbnail tag.
        def thumbnail( attr = {} )
          attr = attr.collect {|k,v| "#{k}='#{v}'"}.join( ' ' )
          if !@data['thumbnail'].to_s.empty? && @data['thumbnail'] != @filename
            "<img src=\"#{@data['thumbnail']}\" alt=\"#{@title}\" #{attr}/>"
          else
            width, height = (@data['thumbnailSize'] || '').split('x')
            "<img src=\"#{@filename}\" width=\"#{width}\" height=\"#{height}\" alt=\"#{@title}\" #{attr}/>"
          end
        end

      end

      attr_reader :galleries
      attr_reader :gIndex
      attr_reader :iIndex

      def initialize( galleries, gIndex = nil, iIndex = nil )
        @galleries = galleries
        @gIndex = gIndex
        @iIndex = iIndex
      end

      # Returns the current image.
      def cur_image
        @galleries[@gIndex].images[@iIndex]
      end

      # Returns the previous image using the given +gIndex+ and +iIndex+, if it exists, or +nil+ otherwise.
      def prev_image( gIndex = @gIndex, iIndex = @iIndex )
        result = nil
        if gIndex != 0 || iIndex != 0
          if iIndex == 0
            result = @galleries[gIndex - 1].images[@galleries[gIndex - 1].images.length - 1]
          else
            result = @galleries[gIndex].images[iIndex - 1]
          end
        end
        return result
      end

      # Returns the next image using the given +gIndex+ and +iIndex+, if it exists, or +nil+ otherwise.
      def next_image( gIndex = @gIndex, iIndex = @iIndex )
        result = nil
        if gIndex != @galleries.length - 1 || iIndex != @galleries[gIndex].images.length - 1
          if iIndex == @galleries[gIndex].images.length - 1
            result = @galleries[gIndex + 1].images[0]
          else
            result = @galleries[gIndex].images[iIndex + 1]
          end
        end
        return result
      end

      def cur_gallery
        galleries[@gIndex]
      end

      # Returns the previous gallery using the given +gIndex+, if it exists, or +nil+ otherwise.
      def prev_gallery( gIndex = @gIndex )
        gIndex != 0 ? @galleries[gIndex - 1] : nil
      end

      # Returns the next gallery using the given +gIndex+, if it exists, or +nil+ otherwise.
      def next_gallery( gIndex = @gIndex )
        gIndex != @galleries.length - 1 ? @galleries[gIndex + 1] : nil
      end

    end


    infos :summary => "Handles images gallery files"

    handle_extension 'gallery'

    param "imagesPerPage", 20, 'Number of images per gallery page'
    param "thumbnailSize", "100x100", "The size of the thumbnails"
    param "galleryPageTemplate", 'gallery_gallery.template', 'The template for gallery pages. ' +
      'If nil or a not existing file is specified, the default template is used.'
    param "imagePageTemplate", 'gallery_image.template', 'The template for image pages. ' +
      'If nil or a not existing file is specified, the default template is used.'
    param "mainPageTemplate", 'gallery_main.template', 'The template for the main page. ' +
      'If nil or a not existing file is specified, the default template is used.'
    param "images", 'images/**/*.jpg', 'The Dir glob for specifying the image files'

=begin
TODO: move to doc
- inMenu can be specified in the gallery, image, main templates and overrriden for the image templates by the pages
- used keys for configuration section:
  - all params
  - title (if not specified, capitalized name of file will be used)
  - mainPageMetaData
  - galleryPagesMetaData (if orderInfo is specified, it will be used for the first gallery page, next one orderInfo + 1 and so on)
- used keys for image meta data
  - 

=end

    def create_node( file, parent )
      @filedata = {}
      @imagedata = {}
      begin
        filedata = []
        YAML::load_documents( File.read( file ) ) {|d| filedata << d}
        @filedata = filedata[0] if filedata[0].kind_of?( Hash )
        @imagedata = filedata[1] if filedata[1].kind_of?( Hash )
      rescue
        log(:error) { "Could not parse gallery file <#{file}>, not creating gallery pages" }
        return
      end

      @path = File.dirname( file )
      images = Dir[File.join( @path, param( 'images' ))].collect {|i| i.sub( /#{@path + File::SEPARATOR}/, '' ) }
      images.sort! do |a,b|
        aoi = @imagedata[a].nil? ? 0 : @imagedata[a]['orderInfo'].to_s.to_i || 0
        boi = @imagedata[b].nil? ? 0 : @imagedata[b]['orderInfo'].to_s.to_i || 0
        atitle = @imagedata[a].nil? ? a : @imagedata[a]['title'] || a
        btitle = @imagedata[b].nil? ? b : @imagedata[b]['title'] || b
        (aoi == boi ? atitle <=> btitle : aoi <=> boi)
      end

      @filedata['title'] ||= File.basename( file, '.*' ).capitalize
      log(:info) { "Creating gallery for file <#{file}> with #{images.length} images" }
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
    def param( name, plugin = nil )
      ( @filedata.has_key?( name ) ? @filedata[name] : super )
    end

    def page_data( metainfo )
      temp = metainfo.to_yaml
      temp = "---\n" + temp unless /^---\s$/ =~ temp
      "#{temp}\n---\n"
    end

    def create_gallery( images, parent )
      mainData = main_page_data
      galleries = create_gallery_pages( images, parent )
      info_galleries = galleries.collect {|n,g,i| g}

      if images.length > param( 'imagesPerPage' )
        mainNode = @plugin_manager['FileHandlers::PageFileHandler'].create_node_from_data( gallery_file_name( mainData['title'] ), parent, page_data( mainData ) )
        mainNode.node_info[:ginfo] = GalleryInfo.new( info_galleries )
      end

      galleries.each_with_index do |gData, gIndex|
        gData[0].node_info[:ginfo] = GalleryInfo.new( info_galleries, gIndex )
        gData[2].each_with_index do |iData, iIndex|
          iData[0].node_info[:ginfo] = GalleryInfo.new( info_galleries, gIndex, iIndex )
        end
      end

    end

    def main_page_data
      main = {}
      main['title'] = param( 'title' )
      main['template'] = param( 'mainPageTemplate' )
      main.update( @filedata['mainPageMetaData'] || {} )
      main
    end

    def create_gallery_pages( images, parent )
      galleries = []
      picsPerPage = param( 'imagesPerPage' )
      0.step( images.length - 1, picsPerPage ) do |i|
        gIndex = i/picsPerPage + 1

        data = (@filedata['galleryPagesMetaData'] || {}).dup
        data['template'] ||= param( 'galleryPageTemplate' )
        data['orderInfo'] += gIndex if data['orderInfo']
        data['title'] = param( 'title' ) + ' ' + gIndex.to_s

        if images.length <= param( 'imagesPerPage' ) && gIndex == 1
          template = data['template']
          data.update( main_page_data )
          data['template'] = template
        end

        node = @plugin_manager['FileHandlers::PageFileHandler'].create_node_from_data( gallery_file_name( data['title'] ), parent, page_data( data ) )
        gal_images = create_image_pages( images[i..(i + picsPerPage - 1)], parent )
        gallery = GalleryInfo::Gallery.new( node.path, gal_images.collect {|n,i| i}, data )
        galleries << [node, gallery, gal_images]
      end
      galleries
    end

    def gallery_file_name( title )
      ( title.nil? ? nil : title.tr( ' .', '_' ) + '.page' )
    end

    def create_image_pages( images, parent )
      imageList = []
      images.each do |image|
        data = (@imagedata[image] || {}).dup
        data['template'] ||= param( 'imagePageTemplate' )
        data['title'] ||= "Image #{File.basename( image )}"
        data['thumbnailSize'] ||= param( 'thumbnailSize' )
        data['thumbnail'] ||= get_thumbnail( image, data, parent )

        filename = param( 'title' ) + ' ' + image.tr( '\\/', '_' )
        node = @plugin_manager['FileHandlers::PageFileHandler'].create_node_from_data( gallery_file_name( filename ), parent, page_data( data ) )
        image = GalleryInfo::Image.new( node.path, image, data )
        imageList << [node, image]
      end
      imageList
    end

    def get_thumbnail( image, data, parent )
      image
    end

  end

  # Try to use RMagick as thumbnail creator
  begin
    require 'RMagick'

    class GalleryFileHandler

      remove_method :get_thumbnail
      def get_thumbnail( image, data, parent )
        parent_node = @plugin_manager['FileHandlers::DirectoryHandler'].recursive_create_path( File.dirname( image ), parent )
        node = @plugin_manager['FileHandlers::ThumbnailWriter'].create_node( File.join( @path, image ), parent_node, data['thumbnailSize'] )
        node.absolute_path
      end

    end

    class ThumbnailWriter < DefaultFileHandler

      infos :summary => "Writes out thumbnails with RMagick"

      def create_node( file, parent, thumbnailSize = nil )
        node = Node.new( parent, 'tn_' + File.basename( file ) )
        node['title'] = node.path
        node.node_info[:thumbnail_size] = thumbnailSize
        node.node_info[:thumbnail_file] = file
        node.node_info[:processor] = self
        node
      end

      def write_node( node )
        if @plugin_manager['FileHandlers::FileHandler'].file_modified?( node.node_info[:thumbnail_file], node.full_path )
          log(:info) {"Creating thumbnail <#{node.full_path}> from <#{node.node_info[:thumbnail_file]}>"}
          image = Magick::ImageList.new( node.node_info[:thumbnail_file] )
          image.change_geometry( node.node_info[:thumbnail_size] ) {|c,r,i| i.resize!( c, r )}
          image.write( node.full_path )
        end
      end

    end

  rescue LoadError => e
    $stderr.puts( "Could not load RMagick, creation of thumbnails not available: #{e.message}" ) if $VERBOSE
  end

end
