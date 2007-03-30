module Support

  class WebsiteManager

    class Resource

      attr_reader :path
      attr_reader :infos

      def initialize( path )
        @path = path
        @infos = YAML::load( File.read( File.join( path, 'README' ) ) ) rescue {}
        @infos = {} unless @infos.kind_of?( Hash )
      end

      def files
        @files = Dir[File.join( @path, '**', '*' )] - [File.join( @path, 'README' )]
      end

      def copy_to( dest )
        files.collect do |file|
          destpath = File.join( dest, File.dirname( file.sub( /^#{@path}/, '/' ) ) )
          FileUtils.mkdir_p( File.dirname( destpath ) )
          if File.directory?( file )
            FileUtils.mkdir_p( File.join( destpath, File.basename( file ) ) )
          else
            FileUtils.cp( file, destpath )
          end
          File.join( destpath, File.basename( file ) )
        end
      end

    end


    attr_reader :templates
    attr_reader :styles

    def initialize
      @templates = {}
      @styles = Hash.new( {} )
    end


    # The absolute directory path. Requires that child classes have defined a constant +BASE_PATH+.
    def path
      File.expand_path( File.join( self.class::BASE_PATH, name ) )
    end

    def init_plugin
      @plugin_manager.resources[%r{^webgen/website/template/}].each do |name, res_infos|
        res = Resource.new( res_infos['src'] )
        name = name.split( '/' ).last
        @templates[name] = res
      end
      @plugin_manager.resources[%r{^webgen/website/style/}].each do |name, res_infos|
        style_type = name.sub( %r{^webgen/website/style/}, '' )[/^\w+/].to_sym
        res = Resource.new( res_infos['src'] )
        name = name.split( '/' ).last
        (@styles[style_type.to_sym] ||= {})[name] = res
      end
    end

    # Create a website in the +directory+, using the template +template_name+.
    def create_website( directory, template_name = 'default' )
      template = @templates[template_name]
      raise ArgumentError.new( "Invalid website template '#{template_name}'" ) if template.nil?

      raise ArgumentError.new( "Directory <#{directory}> does already exist!") if File.exists?( directory )
      FileUtils.mkdir( directory )
      return template.copy_to( directory )
    end

    def use_style( directory, style_category, style_name )
      style = @styles[style_category][style_name]
      raise ArgumentError.new( "Invalid style: '#{style_category}/#{style_name}'" ) if style.nil?

      raise ArgumentError.new( "Directory <#{directory}> does not exist!") unless File.exists?( directory )
      return style.copy_to( directory )
    end

    #######
    private
    #######

  end

end
