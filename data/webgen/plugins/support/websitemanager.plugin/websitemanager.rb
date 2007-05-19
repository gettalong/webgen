module Support

  # This plugin can be used to manage webgen websites. It provides access to website templates and
  # styles defined as resources and makes it easy to copy them to a webgen website.
  class WebsiteManager

    # This class is used to store information about website templates and styles and also provides
    # methods for manipulating them.
    class Resource

      # The path of the resource.
      attr_reader :path

      # A hash with information about the resource.
      attr_reader :infos

      # Creates a new Resource from the given +path+. Information is loaded from the file +README+
      # under the path (no error raised if this file does not exist).
      def initialize( path )
        @path = path
        @infos = YAML::load( File.read( File.join( path, 'README' ) ) ) rescue {}
        @infos = {} unless @infos.kind_of?( Hash )
      end

      # Returns all files for the resource.
      def files
        @files = Dir[File.join( @path, '**', '*' )] - [File.join( @path, 'README' )]
      end

      # Copies the files returned by <tt>#files</tt> into the directory +dest+, preserving the
      # directory hierarchy.
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

    # Returns a new WebsiteManager object.
    def initialize
      reset
    end

    # Returns a hash with all available template resources.
    def templates
      update_resources
      @templates
    end

    # Returns a hash with all available style resources.
    def styles
      update_resources
      @styles
    end

    # Creates a website in the +directory+ by copying the main website skeleton and the template
    # specified by +template_name+
    def create_website( directory, template_name = 'default' )
      template = self.templates[template_name]
      raise ArgumentError.new( "Invalid website template '#{template_name}'" ) if template.nil?

      raise ArgumentError.new( "Directory <#{directory}> does already exist!") if File.exists?( directory )
      FileUtils.mkdir( directory )
      skel_files = (@website_skeleton.nil? ? [] : @website_skeleton.copy_to( directory ))
      return skel_files + template.copy_to( directory )
    end

    # Copies the style +style_name+ of the category +style_category+ to the +directory+, overwriting
    # existing files.
    def use_style( directory, style_category, style_name )
      style = self.styles[style_category][style_name]
      raise ArgumentError.new( "Invalid style: '#{style_category}/#{style_name}'" ) if style.nil?

      raise ArgumentError.new( "Directory <#{directory}> does not exist!") unless File.exists?( directory )
      return style.copy_to( directory )
    end

    #######
    private
    #######

    def reset
      @website_skeleton = nil
      @templates = {}
      @styles = Hash.new {|h,k| h[k] = {} }
      @cached_resources_hash = nil
    end

    def update_resources
      return unless @plugin_manager.resources.hash != @cached_resources_hash
      reset

      if skeleton = @plugin_manager.resources['webgen/website/skeleton']
        @website_skeleton = Resource.new( skeleton['src'] )
      end
      @plugin_manager.resources[%r{^webgen/website/template/}].each do |name, res_infos|
        res = Resource.new( res_infos['src'] )
        name = name.split( '/' ).last
        @templates[name] = res
      end
      @plugin_manager.resources[%r{^webgen/website/style/}].each do |name, res_infos|
        style_type = name.sub( %r{^webgen/website/style/}, '' )[/^\w+/]
        res = Resource.new( res_infos['src'] )
        name = name.split( '/' ).last
        (@styles[style_type] ||= {})[name] = res
      end
      @cached_resources_hash = @plugin_manager.resources.hash
    end

  end

end
