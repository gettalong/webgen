# -*- encoding: utf-8 -*-

require 'rbconfig'

module Webgen

  # This class is used for loading extensions. It provides a DSL for the most commonly needed
  # commands.
  #
  # When an extension is provided by a Rubygem and the Rubygem is not already activated, the
  # extension is not automatically loaded. One has to manually activate the needed Rubygem using the
  # +gem+ method!
  class ExtensionLoader

    # Create a new ExtensionLoader object belonging to the website object +website+.
    def initialize(website, ext_dir)
      @website = website
      @ext_dir = ext_dir
      @loaded = []
      @stack = []
    end

    # Load the extension in the context of this ExtensionLoader object.
    def load(ext_name)
      file = resolve_ext_file(ext_name)
      raise(ArgumentError, "Extension '#{ext_name}' not found") if !file
      file = File.expand_path(file)
      return if @loaded.include?(file)

      @loaded.push(file)
      @stack.push(file)
      self.instance_eval(File.read(file), file)
      @stack.pop
    end

    # Search through the extension directory and then the load path to find the extension loader
    # file.
    def resolve_ext_file(ext_name)
      file_found_check = proc {|path| return path if File.file?(path)}

      ext_name.sub!(/(\/|^)init\.rb$/, '')
      possible_file_names(ext_name).each(&file_found_check)

      begin
        Gem::Specification.new("webgen-#{ext_name}-extension").activate if defined?(Gem)
      rescue Gem::LoadError
      end
      ext_name = "webgen/extension/#{ext_name}" unless ext_name.start_with?("webgen/extension")
      possible_file_names(ext_name).each(&file_found_check)

      nil
    end
    private :resolve_ext_file

    # Create all possible extension loader file names for the given directory name.
    def possible_file_names(ext_dir_name)
      ([@ext_dir] + $LOAD_PATH).map {|path| File.join(path, ext_dir_name, 'init.rb')}
    end
    private :possible_file_names

    # :section: DSL methods
    #
    # All following method are DSL methods that are just provided for convenience.

    # Require the file relative to the currently loaded file.
    def require_relative(file)
      require(File.join(File.dirname(@stack.last), file))
    end

    # Define a configuration option. See Webgen::Configuration#define_option for more information.
    def option(name, default, description, &validator)
      @website.config.define_option(name, default, description, &validator)
    end
    private :option

    # Return the website object.
    def website
      @website
    end
    private :website

  end

end
