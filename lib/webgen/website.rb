# -*- encoding: utf-8 -*-

# Standard lib requires
require 'stringio'
require 'fileutils'
require 'ostruct'

# Requirements for Website
require 'webgen/core_ext'
require 'webgen/utils'
require 'webgen/configuration'
require 'webgen/blackboard'
require 'webgen/cache'
require 'webgen/error'
require 'webgen/tree'
require 'webgen/bundle_loader'
require 'webgen/logger'

# Load other needed files
require 'webgen/path'
require 'webgen/node'
require 'webgen/page'
require 'webgen/version'


module Webgen

  #
  # == About
  #
  # Represents a webgen website and provides the main interface for users.
  #
  # Normally, webgen is used from the command line via the +webgen+ command or from Rakefiles via
  # Webgen::RakeTask. However, you can also easily use webgen as a library and this class provides
  # the interface for this usage!
  #
  # You may notice that this class doesn't have many methods. This is because webgen is designed
  # from ground up to be extensible. Most of the 'magic' happens in extensions which are registered
  # on the #ext OpenStruct object. The simple 'core' classes that are not extensions have separate
  # accessor methods (#config for the Configuration object, #blackboard for the Blackboard and so
  # on).
  #
  # Since a webgen website is, basically, just a directory, the only parameter needed for creating a
  # new Website object is the website directory. Once created, the website is fully initialized and
  # one can work with it:
  #
  # * If you want to generate the website, you just need to call #execute_task with
  #   :generate_website as parameter.
  #
  # * If you want to retrieve data from the website, you can use the various accessors on the
  #   Website object itself or use #ext to access all available extensions.
  #
  #   *Note*: This is generally only useful if the website has been generated before because
  #   otherwise there probably is no data to retrieve.
  #
  class Website

    # The website configuration.
    attr_reader :config

    # The blackboard used for inter-object communication.
    attr_reader :blackboard

    # A cache to store information that should be available the next time the website gets
    # generated.
    attr_reader :cache

    # Access to all extension objects. An OpenStruct object.
    attr_reader :ext

    # The internal data structure used to store information about individual nodes.
    #
    # See Tree for more information
    attr_reader :tree

    # The Webgen::Logger used for logging.
    attr_reader :logger

    # The website directory.
    attr_reader :directory

    # Create a new webgen Website object for the website in the directory +dir+.
    #
    # If no logger is specified, a dummy logger that logs to a StringIO is created.
    #
    # You can provide a block for modifying the Website object in any way during the initialization:
    #
    # * If the block only takes one parameter, it is called with the Website object after the
    #   initialization is done but before the cache is restored.
    #
    # * If it takes two parameters, the first one is the Website object and the second one is a
    #   boolean specifying whether the block is currently called any initialization (value is
    #   +true+) or after it (value is +false).
    #
    def initialize(dir, logger = nil, &block)
      @directory = dir
      @logger = logger || Webgen::Logger.new(StringIO.new)
      @init_block = block
      init
    end

    # Initialize the configuration, blackboard and cache objects and load the default configuration
    # as well as all specified extensions.
    def init
      @tree = Tree.new(self)
      @blackboard = Blackboard.new
      @config = Configuration.new
      @cache = nil
      @ext = OpenStruct.new

      @init_block.call(self, true) if @init_block && @init_block.arity == 2
      loader = load_bundles
      load_configuration(loader)
      if @init_block
        @init_block.arity == 1 ? @init_block.call(self) : @init_block.call(self, false)
      end
      @config.freeze

      restore_cache
      @blackboard.dispatch_msg(:website_initialized)
    end
    private :init

    # Load all extension bundles.
    #
    # This loads the extension bundle for the built-in extensions as well as all website specific
    # extension bundles.
    def load_bundles
      ext_dir = File.join(@directory, 'ext')
      ext_loader = BundleLoader.new(self, ext_dir)
      ext_loader.load('built-in')
      ext_loader.load_autoload_bundles
      Dir[File.join(ext_dir, '**/init.rb')].sort.each {|file| ext_loader.load(file[ext_dir.length..-1])}
      ext_loader.load('init.rb') if File.file?(File.join(ext_dir, 'init.rb'))
      ext_loader
    end
    private :load_bundles

    # The name of the configuration file webgen uses.
    CONFIG_FILENAME = 'webgen.config'

    # Load the configuration file into the Configuration object.
    #
    # If it is a Ruby configuration file, the given bundle loader is used to load it.
    def load_configuration(bundle_loader)
      config_file = File.join(@directory, CONFIG_FILENAME)
      return unless File.exist?(config_file)

      first_line = File.open(config_file, 'r') {|f| f.gets}
      if first_line =~ /^\s*#.*\bruby\b/i
        begin
          bundle_loader.load!(config_file)
        rescue Exception => e
          raise Webgen::Error.new("Couldn't load webgen configuration file (using Ruby syntax):\n#{e.message}")
        end
      else
        unknown_options = @config.load_from_file(config_file)
        @logger.vinfo { "Configuration data loaded from <#{config_file}>" }
        if unknown_options.length > 0
          @logger.debug { "Ignored following unknown options in configuration file: #{unknown_options.join(', ')}" }
        end
      end
    end
    private :load_configuration

    # Restore the cache using the +website.cache+ configuration option.
    def restore_cache
      @cache = Cache.new
      data = if config['website.cache'].first == 'file'
               File.binread(cache_file) if File.file?(cache_file)
             else
               config['website.cache'].last
             end
      cache_data, version = Marshal.load(data) rescue nil
      @cache.restore(cache_data) if cache_data && version == Webgen::VERSION
    end
    private :restore_cache

    # Save the +cache+.
    def save_cache
      return if config['website.dry_run']
      cache_data = [@cache.dump, Webgen::VERSION]
      if config['website.cache'].first == 'file'
        File.open(cache_file(true), 'wb') {|f| Marshal.dump(cache_data, f)}
      else
        config['website.cache'][1] = Marshal.dump(cache_data)
      end
    end

    # The full path of the cache filename.
    def cache_file(create_dir = false)
      tmpdir(config['website.cache'].last, create_dir)
    end
    private :cache_file

    # Append the path to the website's temporary directory and return the full path to it.
    #
    # Note that the temporary directory is only created if the +create+ parameter is set to true.
    def tmpdir(path = '', create = false)
      @_tmpdir = File.absolute_path(config['website.tmpdir'], @directory) unless defined?(@_tmpdir)
      FileUtils.mkdir_p(@_tmpdir) if create
      File.join(@_tmpdir, path)
    end

    # Execute the given task.
    #
    # See Webgen::Task and the classes in its namespace for available classes.
    def execute_task(task, *options)
      @ext.task.execute(task, *options)
    end

  end

end
