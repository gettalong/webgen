# Standard lib requires
require 'logger'
require 'set'

# Requirements for Website
require 'webgen/loggable'
require 'webgen/configuration'
require 'webgen/websiteaccess'
require 'webgen/blackboard'
require 'webgen/cache'
require 'webgen/tree'

# Files for autoloading
require 'webgen/source'
require 'webgen/output'
require 'webgen/sourcehandler'
require 'webgen/contentprocessor'

# Load other needed files
require 'webgen/path'
require 'webgen/node'
require 'webgen/page'


# The Webgen namespace houses all classes/modules used by webgen.
module Webgen

  # Returns the data directory for webgen.
  def self.data_dir
    unless defined?(@@data_dir)
      require 'rbconfig'
      @@data_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'data', 'webgen'))
      @@data_dir = File.expand_path(File.join(Config::CONFIG["datadir"], "webgen")) if !File.exists?(@@data_dir)
      raise "Could not find webgen data directory! This is a bug, report it please!" unless File.directory?(@@data_dir)
    end
    @@data_dir
  end


  # Represents a webgen website and is used to render it.
  class Website

    include Loggable

    # The website configuration. Can only be used after #init has been called (which is
    # automatically done in #render).
    attr_reader :config

    # The blackboard used for inter-object communication. Can only be used after #init has been
    # called.
    attr_reader :blackboard

    # A cache to store information that should be available between runs. Should only be used during
    # rendering as the cache gets restored before rendering and saved afterwards!
    attr_reader :cache

    # The logger used for logging. If none is set, logging is disabled.
    attr_accessor :logger

    # The website directory.
    attr_reader :directory

    # Create a new webgen website for the website in the directory +dir+. You can provide a
    # block (has to take the configuration object as parameter) for adjusting the configuration
    # values during the initialization.
    def initialize(dir, &block)
      @blackboard = nil
      @cache = nil
      @config_block = block
      @directory = dir
    end

    # Define a service +service_name+ provided by the instance of +klass+. The parameter +method+
    # needs to define the method which should be invoked when the service is invoked. Can only be
    # used after #init has been called.
    def autoload_service(service_name, klass, method = service_name)
      blackboard.add_service(service_name) {|*args| cache.instance(klass).send(method, *args)}
    end

    # Initialize the configuration and blackboard objects and load the default configuration as well
    # as website specific extension files. An already existing configuration/blackboard is deleted!
    def init
      with_thread_var do
        @blackboard = Blackboard.new
        @config = Configuration.new

        load 'webgen/default_config.rb'
        @config['website.dir'] = @directory.to_s
        Dir.glob(File.join(@config['website.dir'], 'ext', '**/*_init.rb')) {|f| load(f) }

        @config_block.call(@config) if @config_block
      end
    end

    # Render the website.
    def render
      with_thread_var do
        init
        log(:info) {"Starting webgen..."}

        shm = SourceHandler::Main.new
        tree = restore_tree_and_cache
        shm.render(tree)
        save_tree_and_cache(tree)

        log(:info) {"webgen finished"}
      end
    end

    #######
    private
    #######

    # Restore the tree and the cache from +website.cache+ and returns the Tree object.
    def restore_tree_and_cache
      @cache = Cache.new
      tree = Tree.new
      data = if config['website.cache'].first == :file
               cache_file = File.join(config['website.dir'], config['website.cache'].last)
               File.read(cache_file) if File.exists?(cache_file)
             else
               config['website.cache'].last
             end
      cache_data, tree = Marshal.load(data) rescue nil
      @cache.restore(cache_data) if cache_data
      tree
    end

    # Save the +tree+ and the +@cache+ to +website.cache+.
    def save_tree_and_cache(tree)
      cache_data = [@cache.dump, tree]
      if config['website.cache'].first == :file
        cache_file = File.join(config['website.dir'], config['website.cache'].last)
        File.open(cache_file, 'wb') {|f| Marshal.dump(cache_data, f)}
      else
        config['website.cache'][1] = Marshal.dump(cache_data)
      end
    end

    # Set a thread variable for easy access to the website during rendering.
    def with_thread_var
      set_back = Thread.current[:webgen_website].nil?
      Thread.current[:webgen_website] = self
      yield
    ensure
      Thread.current[:webgen_website] = nil if set_back
    end

  end

end
