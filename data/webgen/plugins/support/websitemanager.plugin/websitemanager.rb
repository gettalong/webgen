module Support

  # This plugin is used for managing webgen websites. It provides access to website templates and
  # styles defined as resources and makes it easy to copy them to a webgen website.
  #
  # = General information
  #
  # Currently, the following actions are supported:
  #
  # * creating a website based on a website template (#create_website)
  # * copying a style to an existing website (#use_style)
  #
  # A website template defines some initial pages which should be filled with real data. For
  # example, the @project@ template defines several pages which are useful for software projects
  # including a features and about page.
  #
  # A style defines, for example, the basic page layout (in the case of website styles) or how image
  # galleries should look like (in the case of gallery styles). So styles are basically used to
  # change the appearance of parts (or the whole) website. This makes them a powerful tool as this
  # plugin makes it easy to change a style later!
  #
  # = website template and style resource naming convention
  #
  # Styles and website templates are defined using resources. Each such resource has to be a
  # directory containing an optional README file in YAML format in which key-value pairs provide
  # additional information about the style or website template. All other files/directories in the
  # directory are copied to the root of the destination webgen website when the style or website
  # template is used.
  #
  # The plugin uses a special naming convention to recognize website templates and styles:
  #
  # * A resource named <tt>webgen/website/template/TEMPLATE_NAME</tt> is considered to be a website
  #   template called TEMPLATE_NAME and can be later accessed using this name.
  #
  # * A resource named <tt>webgen/website/style/CATEGORY/STYLE_NAME</tt> is considered to be a style
  #   in the category CATEGORY called STYLE_NAME. There are no fixed categories, one can use
  #   anything here!  Again, the style can later be accessed by providing the category and style
  #   name.
  #
  # Website template names have to be unique and style names have to be unique in respect to their
  # categories!
  #
  # Note: All styles in the category 'website' are website styles.
  #
  # = Creating a website template or a style
  #
  # First you need to create a new plugin bundle (see Webgen::PluginManager). Then create the
  # following directory structure inside the plugin bundle:
  #
  #   resources/
  #   resources/styles
  #   resources/templates
  #
  # Put your new website template into <tt>resources/templates/TEMPLATE_NAME</tt> and/or your new
  # style into <tt>resources/styles/STYLE_CATEGORY/STYLE_NAME</tt>. After that you need to add the
  # resource definition file with the following content:
  #
  #   resources/templates/*/:
  #     name: webgen/website/template/$basename
  #   resources/styles/*/*/:
  #     name: webgen/website/style/$dir1/$basename
  #
  # These lines automatically add all templates/styles in the above specified directories to the
  # list of available templates/styles.
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
