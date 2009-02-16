# -*- encoding: utf-8 -*-

require 'ostruct'
require 'fileutils'
require 'webgen/website'

module Webgen

  # This class is used for managing webgen websites. It provides access to website templates and
  # styles defined as resources and makes it easy to apply them to a webgen website.
  #
  # = General information
  #
  # Currently, the following actions are supported:
  #
  # * creating a website based on a website template (#create_website)
  # * applying a template to an existing website (#apply_template)
  # * applying a style to an existing website (#apply_style)
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
  # This class uses a special naming convention to recognize website templates and styles:
  #
  # * A resource named <tt>webgen-website-template-TEMPLATE_NAME</tt> is considered to be a website
  #   template called TEMPLATE_NAME and can be later accessed using this name.
  #
  # * A resource named <tt>webgen-website-style-CATEGORY-STYLE_NAME</tt> is considered to be a style
  #   in the category CATEGORY called STYLE_NAME. There are no fixed categories, one can use
  #   anything here!  Again, the style can later be accessed by providing the category and style
  #   name.
  #
  # Website template names have to be unique and style names have to be unique in respect to their
  # categories!
  #
  # Note: All styles without a category or which are in the category 'website' are website styles.
  class WebsiteManager

    # A hash with the available website templates (mapping name to infos).
    attr_reader :templates

    # A hash with the available website styles (mapping name to infos).
    attr_reader :styles

    # The used Website object.
    attr_reader :website

    # Create a new WebsiteManager for the website +dir+.
    def initialize(dir)
      @website = Webgen::Website.new(dir)
      @website.init
      @styles = {}
      @templates = {}

      @website.execute_in_env do
        [['webgen-website-style-', @styles], ['webgen-website-template-', @templates]].each do |prefix, var|
          @website.config['resources'].select {|name, data| name =~ /^#{prefix}/}.each do |name, data|
            paths = Webgen::Source::Resource.new(name).paths
            readme = paths.select {|path| path == '/README' }.first
            paths.delete(readme) if readme
            infos = OpenStruct.new(readme.nil? ? {} : YAML::load(readme.io.data))
            infos.paths = paths
            var[name.sub(prefix, '')] = infos
          end
        end
      end
    end

    # Create the basic website skeleton (without any template or style applied).
    def create_website
      raise "Directory <#{@website.directory}> does already exist!" if File.exists?(@website.directory)
      @website.execute_in_env { write_paths(Webgen::Source::Resource.new('webgen-website-skeleton').paths) }
    end

    # Apply the given +template+ to the website by copying the template files.
    def apply_template(name)
      write_paths_to_website(@templates[name], 'template')
    end

    # Apply the given website style +name+ to the website by copying the styles files.
    def apply_style(name)
      write_paths_to_website(@styles[name], 'style')
    end

    #######
    private
    #######

    # Do some sanity checks and write the +paths+ from +infos+ to the website directory.
    def write_paths_to_website(infos, infos_type)
      raise ArgumentError.new("Invalid #{infos_type} name") if infos.nil?
      raise "Directory <#{@website.directory}> does not exist!" unless File.exists?(@website.directory)
      write_paths(infos.paths)
    end

    # Write the paths to the website directory.
    def write_paths(paths)
      paths.each do |path|
        output_path = File.join(@website.directory, path.path)
        if path.path =~ /\/$/
          FileUtils.mkdir_p(output_path)
        else
          FileUtils.mkdir_p(File.dirname(output_path))
          path.io.stream do |source|
            File.open(output_path, 'wb') {|f| FileUtils.copy_stream(source, f) }
          end
        end
      end
    end

  end

end
