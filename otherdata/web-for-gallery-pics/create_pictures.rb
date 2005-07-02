#!/usr/bin/env ruby

require 'webgen/configuration'
require 'RMagick'

def capture_image
  image = Magick::Image.capture( true, false, false, true ) { self.filename = 'root' }
  image.crop!(0, 105, 1024, 636)
  image.change_geometry( '200x150' ) {|c,r,i| i.resize!( c, r )}
  image
end

Webgen::Plugin['Configuration'].init_all
layouts = Webgen::Plugin.config[GalleryLayouter::DefaultGalleryLayouter].layouts

system('ruby -I../../lib ../../bin/webgen')
system('killall opera')
system('opera -geometry 1024x768+0+0 -newpage `pwd`/output/ &')
sleep( 10 )


layouts.keys.each do |name|
  system("opera `pwd`/output/Gallery_#{name}.html &")
  sleep( 3 )
  image1 = capture_image

  system("opera `pwd`/output/Gallery_#{name}_2.html &")
  sleep( 3 )
  image2 = capture_image

  system("opera `pwd`/output/Gallery_#{name}_webgen3_png.html &")
  sleep( 3 )
  image3 = capture_image

  image = Magick::Image.new( 600, 150)
  image.composite!( image1, 0, 0, Magick::CopyCompositeOp )
  image.composite!( image2, 200, 0, Magick::CopyCompositeOp )
  image.composite!( image3, 400, 0, Magick::CopyCompositeOp )
  image.write( "../../data/webgen/gallery-creator/#{name}.png" )
  puts "Wrote gallery image for layout #{name}"
end

system('killall opera')
