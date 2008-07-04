# Standard lib requires
require 'logger'
require 'set'

# Requirements for Website
require 'webgen/loggable'
require 'webgen/logger'
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

    # Raised when the configuration file of the website is invalid.
    class ConfigFileInvalid < RuntimeError; end

    include Loggable

    # The website configuration. Can only be used after #init has been called (which is
    # automatically done in #render).
    attr_reader :config

    # The blackboard used for inter-object communication. Can only be used after #init has been
    # called.
    attr_reader :blackboard

    # A cache to store information that should be available between runs. Can only be used after
    # #init has been called.
    attr_reader :cache

    # The internal data structure used to store information about individual nodes.
    attr_reader :tree

    # The logger used for logging. If set to +nil+, logging is disabled.
    attr_accessor :logger

    # The website directory.
    attr_reader :directory

    # Create a new webgen website for the website in the directory +dir+. You can provide a
    # block (has to take the configuration object as parameter) for adjusting the configuration
    # values during the initialization.
    def initialize(dir, logger=Webgen::Logger.new($stdout, false), &block)
      @blackboard = nil
      @cache = nil
      @logger = logger
      @config_block = block
      @directory = dir
    end

    # Define a service +service_name+ provided by the instance of +klass+. The parameter +method+
    # needs to define the method which should be invoked when the service is invoked. Can only be
    # used after #init has been called.
    def autoload_service(service_name, klass, method = service_name)
      blackboard.add_service(service_name) {|*args| cache.instance(klass).send(method, *args)}
    end

    # Initialize the configuration, blackboard and cache objects and load the default configuration
    # as well as website specific extension files. An already existing configuration/blackboard is
    # deleted!
    def init
      execute_in_env do
        @blackboard = Blackboard.new
        @config = Configuration.new

        load 'webgen/default_config.rb'
        @config['website.dir'] = @directory.to_s
        Dir.glob(File.join(@config['website.dir'], 'ext', '**/init.rb')) {|f| load(f)}
        read_config_file

        @config_block.call(@config) if @config_block
        restore_tree_and_cache
      end
      self
    end

    # Render the website (after calling #init if the website is not already initialized).
    def render
      execute_in_env do
        init unless @config

        puts "Starting webgen..."
        shm = SourceHandler::Main.new
        shm.render(@tree)
        save_tree_and_cache
        puts "Finished"

        if @logger && @logger.log_output.length > 0
          puts "\nLog messages:"
          puts @logger.log_output
        end
      end
    end

    # Clean the website directory from all generated output files (including the cache file). If
    # +del_outdir+ is +true+, then the base output directory is also deleted. When a delete
    # operation fails, the error is silently ignored and the clean operation continues.
    #
    # Note: Uses the configured output instance for the operations!
    def clean(del_outdir = false)
      init
      execute_in_env do
        output = @blackboard.invoke(:output_instance)
        @tree.node_access[:alcn].each do |name, node|
          next if node.is_fragment? || node['no_output'] || node.path == '/' || node == @tree.dummy_root
          output.delete(node.path) rescue nil
        end

        if @config['website.cache'].first == :file
          FileUtils.rm(File.join(@config['website.dir'], @config['website.cache'].last)) rescue nil
        end

        if del_outdir
          output.delete('/') rescue nil
        end
      end
    end

    # The provided block is executed within a proper environment sothat any object can access the
    # Website object.
    def execute_in_env
      set_back = Thread.current[:webgen_website].nil?
      Thread.current[:webgen_website] = self
      yield
    ensure
      Thread.current[:webgen_website] = nil if set_back
    end

    #######
    private
    #######

    # Restore the tree and the cache from +website.cache+ and returns the Tree object.
    def restore_tree_and_cache
      @cache = Cache.new
      @tree = Tree.new
      data = if config['website.cache'].first == :file
               cache_file = File.join(config['website.dir'], config['website.cache'].last)
               File.read(cache_file) if File.exists?(cache_file)
             else
               config['website.cache'].last
             end
      cache_data, @tree = Marshal.load(data) rescue nil
      @cache.restore(cache_data) if cache_data
    end

    # Save the +tree+ and the +cache+ to +website.cache+.
    def save_tree_and_cache
      cache_data = [@cache.dump, @tree]
      if config['website.cache'].first == :file
        cache_file = File.join(config['website.dir'], config['website.cache'].last)
        File.open(cache_file, 'wb') {|f| Marshal.dump(cache_data, f)}
      else
        config['website.cache'][1] = Marshal.dump(cache_data)
      end
    end

    # Update the configuration object for the website with infos found in the configuration file.
    def read_config_file
      file = File.join(@config['website.dir'], 'config.yaml')
      if File.exists?(file)
        begin
          config = YAML::load(File.read(file)) || {}
          raise 'Structure of config file is not valid, has to be a Hash' if !config.kind_of?(Hash)
          config.each do |key, value|
            if key == 'default_meta_info'
              value.each do |klass_name, options|
                @config['sourcehandler.default_meta_info'][klass_name].update(options)
              end
            else
              @config[key] = value
            end
          end
        rescue RuntimeError, ArgumentError => e
          raise ConfigFileInvalid, "Configuration invalid: " + e.message
        end
      elsif File.exists?(File.join(@config['website.dir'], 'config.yml'))
        log(:warn) { "No configuration file called config.yaml found (there is a config.yml - spelling error?)" }
      end
    end

  end

end
