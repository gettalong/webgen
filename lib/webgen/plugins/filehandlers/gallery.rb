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

load_plugin 'webgen/plugins/filehandlers/filehandler'
load_plugin 'webgen/plugins/filehandlers/directory'
load_plugin 'webgen/plugins/filehandlers/page'

load_optional_part( 'gallery-exif',
                    :needed_gems => ['exifr'],
                    :error_msg => 'EXIF library could not be loaded',
                    :info => 'EXIF information will be available for each image' ) do

  require 'exifr'

end


module FileHandlers

  # Handles image gallery files.
  class GalleryHandler < DefaultHandler

    # Objects of this class represent a whole image gallery and are available in all image gallery
    # page files.
    class GalleryInfo

      # A helper module that allows acessing and changing data via the bracket notation.
      module KeyAccess

        def []( key )
          @data[key]
        end

        def []=( key, value )
          @data[key] = value
        end

      end

      # A helper module which declares common attributes for gallery pages.
      module ItemHelper

        include KeyAccess

        # The name of the page.
        attr_accessor :pagename

        # The title of the page.
        attr_reader :title

        # Meta data for the page.
        attr_reader :data

        def initialize( pagename, data )
          @pagename = pagename
          @title = data['title']
          @data = data
        end

      end


      # Represents the main page of an image gallery.
      class MainPage; include ItemHelper; end

      # Represents an image gallery page.
      class Gallery

        include ItemHelper

        # A list of images for this gallery.
        attr_reader :images

        def initialize( pagename, data, images )
          super( pagename, data )
          @images = images
        end

        # Returns the thumbnail image tag for the gallery.
        def thumbnail( attr = {} )
          @images.first.thumbnail( attr )
        end

      end

      # Represents an image page.
      class Image

        include ItemHelper

        # The name of the image file.
        attr_reader :filename

        def initialize( pagename, data, filename )
          super( pagename, data )
          @filename = filename
        end

        # Returns the thumbnail image tag for the image.
        def thumbnail( attr = {} )
          attr = attr.collect {|k,v| "#{k}='#{v}'"}.join( ' ' )
          if !@data['thumbnail'].to_s.empty? && @data['thumbnail'] != @filename
            "<img src=\"{relocatable: #{@data['thumbnail']}}\" alt=\"#{@title}\" #{attr}/>"
          else
            width, height = (@data['thumbnailSize'] || '').split('x')
            "<img src=\"{relocatable: #{@filename}}\" width=\"#{width}\" height=\"#{height}\" alt=\"#{@title}\" #{attr}/>"
          end
        end

      end

      include KeyAccess

      # The index for the current gallery or +nil+ if there is no current gallery.
      attr_reader :gIndex

      # The index for the current image in the current gallery or +nil+ if there is no current image.
      attr_reader :iIndex

      # The main page object if it exists; otherwise +nil+.
      attr_accessor :mainpage

      # The whole data hahs for the image gallery.
      attr_reader :data

      def initialize( gallery_data, gIndex = nil, iIndex = nil )
        @data = gallery_data
        @gIndex = gIndex
        @iIndex = iIndex
      end

      # Returns the list of gallery objects for this image gallery.
      def galleries
        @data[:galleries]
      end

      # Returns the current image.
      def cur_image
        galleries[@gIndex].images[@iIndex]
      end

      # Returns the previous image using the given +gIndex+ and +iIndex+, if it exists, or +nil+ otherwise.
      def prev_image( gIndex = @gIndex, iIndex = @iIndex )
        result = nil
        if gIndex != 0 || iIndex != 0
          if iIndex == 0
            result = galleries[gIndex - 1].images[galleries[gIndex - 1].images.length - 1]
          else
            result = galleries[gIndex].images[iIndex - 1]
          end
        end
        return result
      end

      # Returns the next image using the given +gIndex+ and +iIndex+, if it exists, or +nil+ otherwise.
      def next_image( gIndex = @gIndex, iIndex = @iIndex )
        result = nil
        if gIndex != galleries.length - 1 || iIndex != galleries[gIndex].images.length - 1
          if iIndex == galleries[gIndex].images.length - 1
            result = galleries[gIndex + 1].images[0]
          else
            result = galleries[gIndex].images[iIndex + 1]
          end
        end
        return result
      end

      # Returns the current gallery.
      def cur_gallery
        galleries[@gIndex]
      end

      # Returns the previous gallery using the given +gIndex+, if it exists, or +nil+ otherwise.
      def prev_gallery( gIndex = @gIndex )
        gIndex != 0 ? galleries[gIndex - 1] : nil
      end

      # Returns the next gallery using the given +gIndex+, if it exists, or +nil+ otherwise.
      def next_gallery( gIndex = @gIndex )
        gIndex != galleries.length - 1 ? galleries[gIndex + 1] : nil
      end

    end

    infos( :name => 'File/GalleryHandler',
           :author => Webgen::AUTHOR,
           :summary => "Handles images gallery files"
           )

    register_extension 'gallery'

    param "imagesPerPage", 20, 'Number of images per gallery page'
    param "galleryPageTemplate", 'gallery_gallery.template', 'The template for gallery pages. ' +
      'If nil or a not existing file is specified, the default template is used.'
    param "imagePageTemplate", 'gallery_image.template', 'The template for image pages. ' +
      'If nil or a not existing file is specified, the default template is used.'
    param "mainPageTemplate", 'gallery_main.template', 'The template for the main page. ' +
      'If nil or a not existing file is specified, the default template is used.'
    param "images", 'images/**/*.jpg', 'The path pattern for specifying the image files'


    def initialize( plugin_manager )
      super
      @filedata = {}
    end

    def create_node( file, parent, meta_info )
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
      ginfo = create_gallery( images, parent )
      @plugin_manager["GalleryLayouter/#{@filedata['layouter']}"].handle_gallery( ginfo, parent ) if @filedata.has_key?('layouter') && @plugin_manager["GalleryLayouter/#{@filedata['layouter']}"]

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
      temp = "---\n" + temp unless /^---\s*$/ =~ temp
      "#{temp}\n---\n"
    end

    def create_page_node( filename, parent, data )
      filehandler = @plugin_manager['Core/FileHandler']
      pagehandler = @plugin_manager['File/PageHandler']
      filehandler.create_node( filename, parent, pagehandler ) do |filename, parent, handler, meta_info|
        pagehandler.create_node_from_data( filename, parent, data, meta_info )
      end
    end

    def create_gallery( images, parent )
      main_data = main_page_data()
      galleries = create_gallery_pages( images, parent )

      info_galleries = galleries.collect {|n,g,i| g}
      main_page_used = images.length > param( 'imagesPerPage' )

      gallery_data = @filedata.dup
      gallery_data[:galleries] = info_galleries
      gallery_data['imagesPerPage'] = param('imagesPerPage'),

      if main_page_used
        main_node = create_page_node( gallery_file_name( main_data['title'] ), parent, page_data( main_data ) )
        main_page = GalleryInfo::MainPage.new( main_node.path, main_data )
        main_node.node_info[:ginfo] = GalleryInfo.new( gallery_data )
        main_node.node_info[:ginfo].mainpage = main_page
      end

      galleries.each_with_index do |gData, gIndex|
        gData[0].node_info[:ginfo] = GalleryInfo.new( gallery_data, gIndex )
        gData[0].node_info[:ginfo].mainpage = main_page if main_page_used
        gData[2].each_with_index do |iData, iIndex|
          iData[0].node_info[:ginfo] = GalleryInfo.new( gallery_data, gIndex, iIndex )
          iData[0].node_info[:ginfo].mainpage = main_page if main_page_used
        end
      end

      GalleryInfo.new( gallery_data )
    end

    def main_page_data
      main = {}
      main['title'] = @filedata['title']
      main['template'] = param( 'mainPageTemplate' )
      main.update( @filedata['mainPageMetaInfo'] || {} )
      main
    end

    def create_gallery_pages( images, parent )
      galleries = []
      picsPerPage = param( 'imagesPerPage' )
      0.step( images.length - 1, picsPerPage ) do |i|
        gIndex = i/picsPerPage + 1

        data = (@filedata['galleryPagesMetaInfo'] || {}).dup
        data['template'] ||= param( 'galleryPageTemplate' )
        data['orderInfo'] += gIndex if data['orderInfo']
        data['title'] = @filedata['title'] + ' ' + gIndex.to_s

        if images.length <= param( 'imagesPerPage' ) && gIndex == 1
          template = data['template']
          data.update( main_page_data )
          data['template'] = template
        end

        node = create_page_node( gallery_file_name( data['title'] ), parent, page_data( data ) )
        gal_images = create_image_pages( images[i..(i + picsPerPage - 1)], parent )
        gallery = GalleryInfo::Gallery.new( node.path, data, gal_images.collect {|n,i| i} )
        galleries << [node, gallery, gal_images]
      end
      galleries
    end

    def gallery_file_name( title )
      ( title.nil? ? nil : title.tr( '/ .\\', '_' ) + '.page' )
    end

    def create_image_pages( images, parent )
      imageList = []
      images.each do |image|
        data = (@imagedata[image] || {}).dup
        data['template'] ||= param( 'imagePageTemplate' )
        data['title'] ||= "Image #{File.basename( image )}"
        data['thumbnailSize'] ||= @filedata['thumbnailSize']
        data['thumbnailResizeMethod'] ||= @filedata['thumbnailResizeMethod']
        data['exif'] ||= exif_data( File.join( parent.node_info[:src], image ) )

        if @filedata.has_key?('layouter') && @plugin_manager["GalleryLayouter/#{@filedata['layouter']}"].respond_to?( :thumbnail_for )
          data['thumbnail'] ||= @plugin_manager["GalleryLayouter/#{@filedata['layouter']}"].thumbnail_for( image, data, parent )
        else
          data['thumbnail'] ||= thumbnail_for( image, data, parent )
        end

        filename = @filedata['title'] + ' ' + image
        node = create_page_node( gallery_file_name( filename ), parent, page_data( data ) )
        image = GalleryInfo::Image.new( node.path, data, image )
        imageList << [node, image]
      end
      imageList
    end

    def exif_data( image )
      if @plugin_manager.optional_part( 'gallery-exif' )[:loaded]
        jpeg = EXIFR::JPEG.new( image ) rescue nil
        if !jpeg.nil? && jpeg.exif?
          exif = jpeg.exif.dup
          exif[:width] = jpeg.width
          exif[:height] = jpeg.height
          exif[:comment] = jpeg.comment
          exif[:bits] = jpeg.bits
          exif
        else
          nil
        end
      else
        nil
      end
    end

    def thumbnail_for( image, data, parent )
      image
    end

  end

  # Try to use RMagick as thumbnail creator
  load_optional_part( 'gallery-thumbnail',
                      :error_msg => "Could not load RMagick, creation of thumbnails not available",
                      :needed_gems => ['rmagick'],
                      :info => 'RMagick will be used to create thumbnails for the images used in an image gallery.' ) do

    require 'RMagick'

    class GalleryHandler

      remove_method :thumbnail_for
      def thumbnail_for( image, data, parent )
        parent_node = @plugin_manager['File/DirectoryHandler'].recursive_create_path( File.dirname( image ), parent )
        tn_handler = @plugin_manager['File/ThumbnailWriter']
        file_handler = @plugin_manager['Core/FileHandler']
        node = file_handler.create_node( File.basename( image ), parent_node, tn_handler ) do |fn, parent, h, mi|
          h.create_node( fn, parent, mi, data['thumbnailSize'], data['thumbnailResizeMethod'] )
        end
        node.absolute_path
      end

    end


    # Used for creating thumbnails for images.
    class ThumbnailWriter < DefaultHandler

      infos( :name => 'File/ThumbnailWriter',
             :author => Webgen::AUTHOR,
             :summary => "Writes out thumbnails with RMagick"
             )

      param "thumbnailSize", "100x100", "The size of the thumbnails"
      param 'resizeMethod', :normal, 'Specifies the algorithm which should be used for generating the thumbnail: ' +
        ':normal (thumbnail fits exactly into given thumbnail size), ' +
        ':cropped (resized to exact thumbnail size, image parts maybe cropped)'

      def create_node( file, parent, meta_info, thumbnailSize = nil, method = nil )
        node = Node.new( parent, 'tn_' + File.basename( file ).tr( ' ', '_' ) )
        node.meta_info.update( meta_info )
        node['title'] = node.path
        node.node_info[:thumbnail_size] = thumbnailSize || param( 'thumbnailSize' )
        node.node_info[:thumbnail_file] = file
        node.node_info[:thumbnail_resize_method] = method || param( 'resizeMethod' )
        node.node_info[:processor] = self
        node
      end

      def write_node( node )
        if @plugin_manager['Core/FileHandler'].file_modified?( node.node_info[:thumbnail_file], node.full_path )
          log(:info) {"Creating thumbnail <#{node.full_path}> from image <#{node.node_info[:thumbnail_file]}>"}
          image = Magick::ImageList.new( node.node_info[:thumbnail_file] ).first
          case node.node_info[:thumbnail_resize_method]
          when :normal then image.change_geometry( node.node_info[:thumbnail_size] ) {|c,r,i| i.resize!( c, r )}
          when :cropped then image.crop_resized!( *node.node_info[:thumbnail_size].split('x').collect {|s| s.to_i} )
          end
          image.write( node.full_path )
        end
      end

    end

  end

end
