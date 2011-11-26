# -*- encoding: utf-8 -*-

require 'ostruct'
require 'fileutils'
require 'webgen/website'

module Webgen

  # This class is used for managing webgen websites. It provides access to website bundles defined
  # as resources and makes it easy to apply them to a webgen website.
  #
  # == General information
  #
  # Currently, the following actions are supported:
  #
  # * creating a website based on a website bundle (#create_website)
  # * applying a bundle to an existing website (#apply_bundle)
  #
  # Bundles are partial webgen websites that contain certain functionality. For example, most of the
  # bundles shipped with webgen are style bundles that define the basic page layout or how image
  # galleries should look like. So style bundles are basically used to change the appearance of
  # parts (or the whole) website. This makes them a powerful tool as this plugin makes it easy to
  # change to another style bundle later!
  #
  # However, not all bundles have to be style bundles. For example, you could as easily create a
  # bundle for a plugin or for a complete website (e.g. a blog template).
  #
  # == website bundle resource naming convention
  #
  # The shipped bundles are defined using resources. Each such resource has to be a directory
  # containing an optional README file in YAML format in which key-value pairs provide additional
  # information about the bundle (e.g. copyright information, description, ...). All other
  # files/directories in the directory are copied to the root of the destination webgen website when
  # the bundle is used.
  #
  # This class uses a special naming convention to recognize website bundles:
  #
  # * A resource named <tt>webgen-website-bundle-CATEGORY-NAME</tt> is considered to be a bundle in
  #   the category CATEGORY called NAME (where CATEGORY is optional). There are no fixed categories,
  #   one can use anything here! The shipped style bundles are located in the 'style' category. You
  #   need to use the the full name, i.e. CATEGORY-NAME, for accessing a bundle later.
  #
  # Website bundle names have to be unique!
  class WebsiteManager

    # A hash with the available website bundles (mapping name to infos).
    attr_reader :bundles

    # The used Website object.
    attr_reader :website

    # Create a new WebsiteManager.
    #
    # If +dir+ is a String, then the website manager is created for the website in the directory
    # +dir+.
    #
    # If +dir+ is a Website object, the website manager is created for the website represented by
    # +dir+. If the website object is initialized if it isn't already.
    def initialize(dir)
      if dir.kind_of?(Webgen::Website)
        @website = dir
        @website.init if @website.config.nil?
      else
        @website = Webgen::Website.new(dir)
        @website.init
      end
      @bundles = {}

      @website.execute_in_env do
        prefix = "webgen-website-bundle-"
        @website.config['resources'].select {|name, data| name =~ /^#{prefix}/}.each do |name, data|
          add_source(Webgen::Source::Resource.new(name), name.sub(prefix, ''))
        end
      end
    end

    # Treat the +source+ as a website bundle and make it available to the WebsiteManager under
    # +name+.
    def add_source(source, name)
      paths = source.paths.dup
      readme = paths.select {|path| path == '/README' }.first
      paths.delete(readme) if readme
      infos = OpenStruct.new(readme.nil? ? {} : YAML::load(readme.io.data)) #TODO: catch psych SyntaxError
      infos.paths = paths
      @bundles[name] = infos
    end

    # Create the basic website skeleton (without any bundle applied).
    def create_website
      raise "Directory <#{@website.directory}> does already exist!" if File.exists?(@website.directory)
      @website.execute_in_env do
        write_paths(Webgen::Source::Resource.new('webgen-website-skeleton').paths) +
          [FileUtils.mkdir_p(File.join(@website.directory, 'src'))] # fixes Rubygems bug (see RF#28393)
      end
    end

    # Apply the given +bundle+ to the website by copying the files.
    def apply_bundle(bundle)
      raise ArgumentError.new("Invalid bundle name") if !@bundles.has_key?(bundle)
      raise "Directory <#{@website.directory}> does not exist!" unless File.exists?(@website.directory)
      write_paths(@bundles[bundle].paths)
    end

    #######
    private
    #######

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
