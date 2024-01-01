# -*- encoding: utf-8 -*-

require 'rbconfig'
require 'webgen/error'
require 'webgen/utils'

module Webgen

  # This class is used for loading extension bundles. It provides a DSL for the most commonly needed
  # commands.
  #
  # When an extension bundle is provided by a Rubygem and the Rubygem is not already activated, the
  # Rubygem is automatically activated. This only works when one follows the standard naming
  # conventions for webgen extension bundles, i.e. the Rubygem has to be named
  # 'webgen-BUNDLE_NAME-bundle'.
  class BundleLoader

    # Exposes information about bundles like author, license, bundle homepage as well as extension
    # and configuration option documentation.
    class BundleInformation

      def initialize #:nodoc:
        @bundles = {}
        @infos = nil
      end

      # Add the bundle +name+ with the given information file to the list of available bundles.
      def add_bundle(name, info_file)
        raise "Bundle information already registered for #{name}" if @bundles.has_key?(name)
        @bundles[name] = info_file
        load_bundle_information unless @infos.nil?
      end

      # Return a hash with information about bundles.
      def bundles
        infos[:bundles]
      end

      # Return a hash with information about extensions.
      def extensions
        infos[:extensions]
      end

      # Return a hash with information about options.
      def options
        infos[:options]
      end

      def infos #:nodoc:
        load_bundle_information if @infos.nil?
        @infos
      end
      private :infos

      def load_bundle_information #:nodoc:
        @infos = {:bundles => {}, :extensions => {}, :options => {}}

        @bundles.each do |bundle, info_file|
          if info_file.nil?
            @infos[:bundles][bundle] = {}
          else
            infos = Utils.yaml_load(File.read(info_file))
            [:extensions, :options].each do |type|
              if data = infos.delete(type.to_s)
                data.each do |name, hash|
                  hash['bundle'] = bundle
                  hash['author'] ||= infos['author']
                end
                @infos[type].update(data)
              end
            end
            @infos[:bundles][bundle] = infos
          end
        end

        @infos
      end
      private :load_bundle_information

    end

    # Create a new BundleLoader object belonging to the website object +website+.
    def initialize(website, ext_dir)
      @website = website
      @website.ext.bundle_infos = BundleInformation.new
      @ext_dir = ext_dir
      @loaded = []
      @stack = []
    end

    # Load the extension bundle in the context of this BundleLoader object.
    def load(name)
      file = resolve_init_file(name)
      raise Webgen::BundleLoadError.new(name) if !file
      file = File.expand_path(file)
      return if @loaded.include?(file)

      load!(file)

      if file != File.expand_path(File.join(@ext_dir, 'init.rb'))
        name = File.basename(File.dirname(file))
        info_file = File.join(File.dirname(file), 'info.yaml')
        @website.ext.bundle_infos.add_bundle(name, File.file?(info_file) ? info_file : nil)
      end
    end

    # Force-loads the given file and does just that (i.e. no checking if file exists and no bundle
    # registration).
    #
    # **Note**: This method should normally not be called in an extension bundle, use the #load
    # method instead.
    def load!(file)
      @loaded.push(file)
      @stack.push(file)
      self.instance_eval(File.read(file), file)
      @stack.pop
    end

    # Loads all bundles that are marked for auto-loading.
    def load_autoload_bundles
      bundles = Gem::Specification.map {|s| s.name }.uniq.map do |gem_name|
        md = /^webgen-(.*)-bundle$/.match(gem_name)
        next unless md
        md[1]
      end.compact

      bundles += $LOAD_PATH.map do |path|
        Dir[File.join(path, 'webgen/bundle', '*')].map {|d| File.basename(d)}
      end.flatten.compact

      bundles.each do |bundle_name|
        file = resolve_init_file(bundle_name)
        next unless file

        info_file = File.join(File.dirname(file), 'info.yaml')
        next unless File.file?(info_file)
        next unless (begin Utils.yaml_load(File.read(info_file))['autoload']; rescue Exception; false end)

        load(bundle_name)
      end
    end

    # Search in the website extension directory and then in the load path to find the initialization
    # file of the bundle.
    def resolve_init_file(name)
      name.sub!(/(\/|^)init\.rb$/, '')

      if name =~ /\A[\w-]+\z/
        begin
          Gem::Specification.find_by_name("webgen-#{name}-bundle").activate
        rescue Gem::LoadError
        end
      end

      possible_init_file_names(name).each {|path| return path if File.file?(path)}

      nil
    end
    private :resolve_init_file

    # Create all possible initialization file names for the given directory name.
    def possible_init_file_names(dir_name)
      [File.join(@ext_dir, dir_name, 'init.rb')] +
        $LOAD_PATH.map {|path| File.join(path, 'webgen/bundle', dir_name, 'init.rb')}
    end
    private :possible_init_file_names

    # :section: DSL methods
    #
    # All following method are DSL methods that are provided for convenience and can be used by the
    # initialization files.

    # Require the file relative to the currently loaded file.
    def require_relative(file)
      require(File.join(File.dirname(@stack.last), file))
    end

    # Define a configuration option.
    #
    # See Webgen::Configuration#define_option for more information.
    def option(name, default, &validator)
      @website.config.define_option(name, default, &validator)
    end

    # Return the website object.
    def website
      @website
    end

    # Mount the directory relative to the currently loaded file on the given mount point as passive
    # source.
    #
    # See Webgen::Source for more information.
    def mount_passive(dir, mount_point = '/', glob = '{*,**/*}')
      @website.ext.source.passive_sources.unshift([mount_point, :file_system, absolute_path(dir), glob])
    end

    # Return the absolute path of the given path which is assumed to be relative to the currently
    # loaded file.
    def absolute_path(path)
      File.expand_path(File.join(File.dirname(@stack.last), path))
    end

  end

end
