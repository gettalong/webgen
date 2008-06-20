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

module Webgen

  # Used to render a website.
  class Website

    include Loggable

    # The website configuration. Can only be used after #init has been called (which is done in
    # #render).
    attr_reader :config

    # The logger used for logging
    attr_accessor :logger

    # The blackboard used for inter-object communication
    attr_reader :blackboard

    # A cache to store information that should be available between runs. Should only be used during
    # rendering as the cache gets restored before rendering and save afterwards!
    attr_reader :cache

    # Creates a new webgen website. You can provide a block (has to take the configuration object as
    # parameter) for adjusting the configuration values.
    def initialize(&block)
      @blackboard = Blackboard.new
      @cache = nil
      @config_block = block
    end

    # Defines a service +service_name+ provided by the instance of +klass+. The parameter +method+
    # needs to define the method which should be invoked when the service is invoked.
    def autoload_service(service_name, klass, method = service_name)
      blackboard.add_service(service_name) {|*args| cache.instance(klass).send(method, *args)}
    end

    # Loads all plugin and configuration information.
    def init
      with_thread_var do
        @config = Configuration.new
        load 'webgen/default_config.rb'
        #TODO load site specific files/config
        @config_block.call(@config) if @config_block
      end
    end

    # Render the website.
    def render
      with_thread_var do
        @logger = Logger.new(STDERR) unless defined?(@logger)
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

    def save_tree_and_cache(tree)
      cache_data = [@cache.dump, tree]
      if config['website.cache'].first == :file
        cache_file = File.join(config['website.dir'], config['website.cache'].last)
        File.open(cache_file, 'wb') {|f| Marshal.dump(cache_data, f)}
      else
        config['website.cache'][1] = Marshal.dump(cache_data)
      end
    end

    def with_thread_var
      set_back = Thread.current[:webgen_website].nil?
      Thread.current[:webgen_website] = self
      yield
    ensure
      Thread.current[:webgen_website] = nil if set_back
    end

  end

end
