require 'yaml'
require 'webgen/plugins/filehandler/filehandler'
require 'webgen/plugins/filehandler/gallery'

module FileHandlers

  class GallerySampler < DefaultFileHandler

    summary "Creates gallery samples"
    extension 'sample'
    depends_on 'FileHandler'


    def create_node( path, parent )
      layouts = Webgen::Plugin.config[GalleryLayouter::DefaultGalleryLayouter].layouts
      data = YAML::load( File.read( path ) )
      layouts.keys.each do |name|
        data['layout'] = name
        data['title'] = "Gallery #{name}"
        File.open( path, 'w+' ) {|file| file.write( data.to_yaml )}
        Webgen::Plugin['GalleryFileHandler'].create_node( path, parent )
      end
      nil
    end

    def write_node( node )
      # nothing to write
    end

  end

end
