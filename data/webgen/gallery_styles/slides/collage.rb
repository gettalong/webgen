load_plugin 'webgen/plugins/filehandlers/filehandler'

require 'rubygems'
require 'RMagick'

module Collage

  class Layouter < Webgen::Plugin

    infos( :name => 'GalleryLayouter/slides',
           :author => Webgen::AUTHOR,
           :summary => 'Handles additional tasks for the gallery layout \'slides\''
           )

    depends_on 'Core/ResourceManager'

    def initialize( plugin_manager )
      super
      @plugin_manager['Core/ResourceManager'].append_data( 'webgen-css', '
.thumb {
  display:block;
  }
')
    end

    def handle_gallery( ginfo, parent )
      # Create collage node
      collage_writer = @plugin_manager['File/CollageWriter']
      file_handler = @plugin_manager['Core/FileHandler']
      node = file_handler.create_node( collage_name( ginfo ), parent, collage_writer ) do |fn, parent, h, mi|
        h.create_node( fn, parent, mi, {:parent => parent, :ginfo => ginfo} )
      end
      ginfo[:collage_node] = node

      # Create collage thumbnail node
      collage_thumb_writer = @plugin_manager['File/CollageThumbWriter']
      node = file_handler.create_node( collage_thumb_name( ginfo ), parent, collage_thumb_writer ) do |fn, parent, h, mi|
        h.create_node( fn, parent, mi, {:parent => parent, :ginfo => ginfo} )
      end
      ginfo[:collage_thumb_node] = node

      # Create background slide
      slide_writer = @plugin_manager['File/SlideWriter']
      node = file_handler.create_node( slide_name( ginfo ), parent, slide_writer ) do |fn, parent, h, mi|
        h.create_node( fn, parent, mi, {:parent => parent, :ginfo => ginfo} )
      end
      ginfo[:slide_node] = node

      slide_url = ginfo[:slide_node].to_url
      css_url = slide_url + ( '/' + @plugin_manager['Core/ResourceManager'].get_resource( 'webgen-css' ).output_path )

      @plugin_manager['Core/ResourceManager'].append_data( 'webgen-css', "
.thumb-#{collage_title(ginfo)} {
  background: url(\"#{slide_url.route_from(css_url)}\") 0 0 no-repeat;
  width:  #{ginfo[:slide_node].slide_size[0]}px;
  height: #{ginfo[:slide_node].slide_size[0]}px;
}
.thumb-#{collage_title(ginfo)} img {
  padding: #{ginfo[:slide_node].slide_border_width}px;
}
.thumb-#{collage_title(ginfo)} img:hover {
  border: 1px solid black;
}

}")
    end

    #######
    private
    #######

    def collage_title( ginfo )
      ginfo['title'].tr( ' ', '_' )
    end

    def collage_name( ginfo )
       collage_title( ginfo ) + '_collage.jpg'
    end

    def collage_thumb_name( ginfo )
      collage_title( ginfo ) + '_collage_tn.jpg'
    end

    def slide_name( ginfo )
      collage_title( ginfo ) + '_slide.png'
    end

  end


  class SlideWriter < FileHandlers::DefaultHandler

    include Magick

    infos( :name => 'File/SlideWriter',
           :author => Webgen::AUTHOR,
           :summary => 'Generates a slide background for image thumbnails' )

    param 'borderWidth', 10, 'The width of the slide border'
    param 'color', '#ffffff', 'The color of the slide'

    def create_node( path, parent, meta_info, data )
      node = Node.new( parent, File.basename( path ) )
      node.meta_info.update( meta_info )
      node.node_info[:data] = data
      node.node_info[:processor] = self

      node
    end

    def slide_size( node )
      (node.node_info[:data][:ginfo]['thumbnailSize'] || param( 'thumbnailSize', 'File/ThumbnailWriter' )).split('x').collect{ |s| s.to_i + slide_border_width( node )*2 }
    end

    def slide_color( node )
      node.node_info[:data][:ginfo]['slideColor'] || param( 'color' )
    end

    def slide_border_width( node )
      node.node_info[:data][:ginfo]['slideBorderWidth'] || param( 'borderWidth' )
    end

    def create_slide( node )
      return if node.node_info[:slide]

      ginfo = node.node_info[:data][:ginfo]

      width, height = node.slide_size
      border_width = node.slide_border_width

      slide = Image.new( width, height ) { self.background_color = 'transparent' }

      gc = Magick::Draw.new
      gc.fill_opacity(0)
      gc.stroke( node.slide_color )
      gc.stroke_width( border_width )
      gc.roundrectangle( border_width/2, border_width/2, width-border_width/2, height-border_width/2, 5, 5)
      gc.draw(slide)

      node.node_info[:slide] = slide
    end

    def write_node( node )
      return if File.exists?( node.full_path ) #TODO always create? what settings to check?
      create_slide( node )
      node.node_info[:slide].write( node.full_path )
    end

  end


  # Most of the code in create_slide, backandforth and creat_collage is from Corban Brook from
  # his tutorial
  # http://schf.uc.org/articles/2006/10/18/render-greatlooking-collages-with-ruby-and-rmagick
  # and has slightly been adapted for use in this gallery style.
  class CollageWriter < FileHandlers::DefaultHandler

    include Magick

    infos( :name => 'File/CollageWriter',
           :author => Webgen::AUTHOR,
           :summary => 'Generates a pretty collage for the main gallery page' )

    param 'size', '700x300', 'The size of the generated collage'
    param 'color', '#CCCCCC', 'The background color of the collage'

    def create_node( path, parent, meta_info, data )
      node = Node.new( parent, File.basename( path ) )
      node.meta_info.update( meta_info )
      node.node_info[:data] = data
      node.node_info[:processor] = self
      node
    end

    def collage_size( node )
      (node.node_info[:data][:ginfo]['collageSize'] || param( 'size' )).split('x').collect{ |s| s.to_i}
    end

    def collage_color( node )
      node.node_info[:data][:ginfo]['collageColor'] || param( 'color' )
    end

    def create_collage( node )
      return if node.node_info[:collage]
      parent = node.node_info[:data][:parent]
      ginfo = node.node_info[:data][:ginfo]

      ginfo[:slide_node].create_slide

      width, height = node.collage_size
      slide_border_width = ginfo[:slide_node].slide_border_width
      slide_width, slide_height = ginfo[:slide_node].slide_size

      # create background
      create_collage_background( node )
      collage = node.node_info[:collage_background]

      # fetch four random images
      images = []
      (1..4).each do
        gal_number = rand(ginfo.galleries.length)
        pic_number = rand(ginfo.galleries[gal_number].images.length)
        redo if images.include?( [gal_number, pic_number] )
        images << [gal_number, pic_number]
      end

      # create main image
      base_image = images.shift
      base_image = ginfo.galleries[base_image[0]].images[base_image[1]]
      base_image_file = File.join( parent.node_info[:src], base_image.filename )
      photo = Image.read( base_image_file ).first
      photo.crop_resized!( width - slide_border_width*2, height*2/3 - slide_border_width )
      collage.composite!( photo, slide_border_width, slide_border_width, OverCompositeOp )

      # Arrange the other three images
      (images.size-1).downto(0) do |i|
        image = ginfo.galleries[i[0]].images[i[1]]
        image_file = File.join( parent.node_info[:src], image.filename )
        slide = create_slide( ginfo, image_file, slide_width, slide_height, slide_border_width )
        collage.composite!( slide, width/2 - slide_width*3/2 + i * slide_width*2/3 + rand(15),
                             height*2/3 - slide_height*2/3 + rand(15), OverCompositeOp)
      end

      node.node_info[:collage] = collage
    end

    def write_node( node )
      return if File.exists?( node.full_path ) #TODO always create? what settings to check?
      create_collage( node )
      node.node_info[:collage].write( node.full_path )
    end

    #######
    private
    #######

    def create_collage_background( node )
      return if node.node_info[:collage_background]

      ginfo = node.node_info[:data][:ginfo]
      width, height = node.collage_size
      color = node.collage_color
      slide_color = ginfo[:slide_node].slide_color
      slide_border_width = ginfo[:slide_node].slide_border_width

      temp = Image.new( width, height ) { self.background_color = color }
      pic = Image.new( width, height) { self.background_color = 'transparent' }

      gc = Draw.new
      gc.fill( color )
      gc.stroke( slide_color )
      gc.stroke_width( slide_border_width )
      gc.rectangle( slide_border_width/2, slide_border_width/2, width-slide_border_width/2-3, height*2/3 )
      gc.draw(pic)

      shadow = pic.shadow( 0, 0, 0.1, '20%' )
      temp.composite!( shadow, 3, 3, OverCompositeOp )
      temp.composite!( pic, 0, 0, OverCompositeOp )

      node.node_info[:collage_background] = temp
    end

    def backandforth(degree)
      polarity = rand(2) * -1
      (polarity < 0 ? rand(degree) * polarity : rand(degree) )
    end

    def create_slide( ginfo, filename, s_width, s_height, s_border_width )
      slide = ginfo[:slide_node].node_info[:slide].clone
      slide_background = Image.new( slide.columns, slide.rows ) { self.background_color = 'transparent' }
      photo = Image.read( filename ).first

      i_width = s_width - s_border_width*2
      i_height = s_height - s_border_width*2

      # create a grey scale gradient fill for our mask
      mask_fill = GradientFill.new( 0, 0, 0, i_height, '#FFFFFF', '#AAAAAA' )
      mask = Image.new( i_width, i_height, mask_fill )
      # create thumbnail sized square image of photo
      photo.crop_resized!( i_width, i_height )

      # apply alpha mask to slide
      photo.matte = true
      mask.matte = false
      photo.composite!( mask, 0, 0, CopyOpacityCompositeOp )

      # composite photo and slide on transparent background
      slide_background.composite!( photo, s_border_width, s_border_width, OverCompositeOp)
      slide_background.composite!( slide, 0, 0, OverCompositeOp)

      # rotate slide a little bit
      slide_background.rotate!( backandforth(40) )

      # create workspace to apply shadow
      workspace = Image.new( slide_background.columns+5, slide_background.rows+5 ) { self.background_color = 'transparent' }
      shadow = slide_background.shadow( 0, 0, 0.1, '20%' )
      workspace.composite!( shadow, 3, 3, OverCompositeOp )
      workspace.composite!( slide_background, NorthWestGravity, OverCompositeOp )

      return workspace
    end

  end


  class CollageThumbWriter < FileHandlers::DefaultHandler

    include Magick

    infos( :name => 'File/CollageThumbWriter',
           :author => Webgen::AUTHOR,
           :summary => 'Generates a thumbnail of a collage image' )

    def create_node( path, parent, meta_info, data )
      node = Node.new( parent, File.basename( path ) )
      node.meta_info.update( meta_info )
      node.node_info[:data] = data
      node.node_info[:processor] = self
      node
    end

    def write_node( node )
      return if File.exists?( node.full_path ) #TODO always create? what settings to check?
      ginfo = node.node_info[:data][:ginfo]
      ginfo[:collage_node].create_collage
      collage = ginfo[:collage_node].node_info[:collage]
      collage.change_geometry( ginfo[:slide_node].slide_size.collect {|s| s*2}.join('x') ) {|c,r,i| i.resize!( c, r )}
      collage.write( node.full_path )
    end

  end


end
