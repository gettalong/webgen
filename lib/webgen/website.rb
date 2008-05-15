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

    # The website configuration
    attr_reader :config

    # The logger used for logging
    attr_accessor :logger

    # The blackboard used for inter-object communication
    attr_reader :blackboard

    # A cache to store information that should be available between runs.
    attr_reader :cache

    # Creates a new webgen website. You can provide a block (has to take the configuration object as
    # parameter) for adjusting the configuration values.
    def initialize(&block)
      @blackboard = Blackboard.new
      @cache = Cache.new
      @config_block = block
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
        @logger = Logger.new(STDERR) unless @logger
        init
        log(:info) {"Starting webgen..."}

        shm = SourceHandler::Main.new

        if File.exists?(cache_file)
          cache_data, tree = Marshal.load(File.read(cache_file))
          @cache.restore(cache_data)
        else
          tree = Tree.new
        end

        shm.render(tree)

        File.open(cache_file, 'wb') {|f| Marshal.dump([@cache.dump, tree], f)}
        log(:info) {"webgen finished"}
      end
    end

    private

    def cache_file
      File.join(config['website.dir'], 'webgen.cache')
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
