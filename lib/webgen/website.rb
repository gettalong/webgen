# -*- encoding: utf-8 -*-

##
# Welcome to the API documentation of wegen!
#
# Have a look at the base <a href=Webgen.html>webgen module</a> which provides a good starting point!


# Standard lib requires
require 'logger'
require 'set'
require 'fileutils'
require 'facets/symbol/to_proc'

# Requirements for Website
require 'webgen/coreext'
require 'webgen/loggable'
require 'webgen/logger'
require 'webgen/configuration'
require 'webgen/websiteaccess'
require 'webgen/blackboard'
require 'webgen/cache'
require 'webgen/tree'

# Files for autoloading
require 'webgen/common'
require 'webgen/context'
require 'webgen/source'
require 'webgen/output'
require 'webgen/sourcehandler'
require 'webgen/contentprocessor'
require 'webgen/tag'

# Load other needed files
require 'webgen/path'
require 'webgen/node'
require 'webgen/page'

# Load deprecated classes/methods/...
require 'webgen/deprecated'


# The Webgen namespace houses all classes/modules used by webgen.
#
# = webgen
#
# webgen is a command line application for generating a web site from templates and content
# files. Despite this fact, the implementation also provides adequate support for using webgen as a
# library and *full* *support* for extending it.
#
# == Extending webgen
#
# webgen can be extended very easily. Any file called <tt>init.rb</tt> put into the <tt>ext/</tt>
# directory of the website or into one of its sub-directories is automatically loaded on
# Website#init.
#
# You can extend webgen in several ways. However, no magic or special knowledge is needed since
# webgen relies on the power of Ruby itself. So, for example, an extension is just a normal Ruby
# class. Most extension types provide a Base module for mixing into an extension which provides
# default implementations for needed methods.
#
# Following are links to detailed descriptions on how to develop specific types of extensions:
#
# [Webgen::Source] Information on how to implement a class that provides source paths for
#                  webgen. For example, one could implement a source class that uses a database as
#                  backend.
#
# [Webgen::Output] Information on how to implement a class that writes content to an output
#                  location. The default output class just writes to the file system. One could, for
#                  example, implement an output class that writes the generated files to multiple
#                  locations or to a remote server.
#
# [Webgen::ContentProcessor] Information on how to develop an extension that processes the
#                            content. For example, markup-to-HTML converters are implemented as
#                            content processors in webgen.
#
# [Webgen::SourceHandler::Base] Information on how to implement a class that handles objects of type
#                               source Path and creates Node instances. For example,
#                               Webgen::SourceHandler::Page handles the conversion of <tt>.page</tt>
#                               files to <tt>.html</tt> files.
#
# [Webgen::Tag::Base] Information on how to implement a webgen tag. webgen tags are used to provide
#                     an easy way for users to include dynamic content such as automatically
#                     generated menus.
#
# == Blackboard services
#
# The Blackboard class provides an easy communication facility between objects. It implements the
# Observer pattern on the one side and allows the definition of services on the other side. One
# advantage of a service over the direct use of an object instance method is that the caller does
# not need to how to find the object that provides the service. It justs uses the Website#blackboard
# instance. An other advantage is that one can easily exchange the place where the service was
# defined without breaking extensions that rely on it.
#
# Following is a list of all services available in the stock webgen distribution by the name and the
# method that implements it (which is useful for looking up the parameters of service).
#
# <tt>:create_fragment_nodes</tt>:: SourceHandler::Fragment#create_fragment_nodes
# <tt>:templates_for_node</tt>:: SourceHandler::Template#templates_for_node
# <tt>:parse_html_headers</tt>:: SourceHandler::Fragment#parse_html_headers
# <tt>:output_instance</tt>:: Output.instance
# <tt>:content_processor_names</tt>:: ContentProcessor.list
# <tt>:content_processor</tt>:: ContentProcessor.for_name
# <tt>:create_sitemap</tt>:: Common::Sitemap#create_sitemap
# <tt>:create_directories</tt>:: SourceHandler::Directory#create_directories
# <tt>:create_nodes</tt>:: SourceHandler::Main#create_nodes
# <tt>:source_paths</tt>:: SourceHandler::Main#find_all_source_paths
#
# Following is the list of all messages that can be listened to:
#
# <tt>:node_flagged</tt>::
#   See Node#flag
#
# <tt>:node_unflagged</tt>::
#   See Node#unflag
#
# <tt>:node_changed?</tt>::
#   See Node#changed?
# <tt>:node_meta_info_changed?</tt>::
#   See Node#meta_info_changed?
#
# <tt>:before_node_created</tt>::
#   Sent by the <tt>:create_nodes</tt> service before a node is created (handled by a source handler)
#   with the +parent+ and the +path+ as arguments.
#
# <tt>:after_node_created</tt>::
#   Sent by the <tt>:create_nodes</tt> service after a node has been created with the created node
#   as argument.
#
# <tt>:before_node_deleted</tt>::
#   See Tree#delete_node
#
# == Other places to look at
#
# Here is a list of modules/classes that are primarily used throughout webgen or provide useful
# methods for developing extensions:
#
# Common, Tree, Node, Path, Cache, Page

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
  #
  # Normally, webgen is used from the command line via the +webgen+ command or from Rakefiles via
  # Webgen::WebgenTask. However, you can also easily use webgen as a library and this class provides
  # the interface for this usage!
  #
  # Since a webgen website is, basically, just a directory, the only parameter needed for creating a
  # new Website object is the website directory. After that you can work with the website:
  #
  # * If you want to render the website, you just need to call Website#render which initializes the
  #   website and does all the rendering. When the method call returns, everything has been rendered.
  #
  # * If you want to remove the generated output, you just need to invoke Website#clean and it will
  #   be done.
  #
  # * Finally, if you want to retrieve data from the website, you first have to call Website#init to
  #   initialize the website. After that you can use the various accessors to retrieve the needed
  #   data. *Note*: This is generally only useful if the website has been rendered because otherwise
  #   there is no data to retrieve.
  #
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
      @config = nil
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
        Dir.glob(File.join(@directory, 'ext', '**/init.rb')) {|f| load(f)}
        read_config_file

        @config_block.call(@config) if @config_block
        restore_tree_and_cache
      end
      self
    end

    # Render the website (after calling #init if the website is not already initialized) and return
    # a status code not equal to +nil+ if rendering was successful.
    def render
      result = nil
      execute_in_env do
        init unless @config

        puts "Starting webgen..."
        shm = SourceHandler::Main.new
        result = shm.render(@tree)
        save_tree_and_cache if result
        puts "Finished"

        if @logger && @logger.log_output.length > 0
          puts "\nLog messages:"
          puts @logger.log_output
        end
      end
      result
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
          FileUtils.rm(File.join(@directory, @config['website.cache'].last)) rescue nil
        end

        if del_outdir
          output.delete('/') rescue nil
        end
      end
    end

    # The provided block is executed within a proper environment sothat any object can access the
    # Website object.
    def execute_in_env
      set_back = Thread.current[:webgen_website]
      Thread.current[:webgen_website] = self
      yield
    ensure
      Thread.current[:webgen_website] = set_back
    end

    #######
    private
    #######

    # Restore the tree and the cache from +website.cache+ and returns the Tree object.
    def restore_tree_and_cache
      @cache = Cache.new
      @tree = Tree.new
      data = if config['website.cache'].first == :file
               cache_file = File.join(@directory, config['website.cache'].last)
               File.open(cache_file, 'rb') {|f| f.read} if File.exists?(cache_file)
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
        cache_file = File.join(@directory, config['website.cache'].last)
        File.open(cache_file, 'wb') {|f| Marshal.dump(cache_data, f)}
      else
        config['website.cache'][1] = Marshal.dump(cache_data)
      end
    end

    # Update the configuration object for the website with infos found in the configuration file.
    def read_config_file
      file = File.join(@directory, 'config.yaml')
      if File.exists?(file)
        begin
          config = YAML::load(File.read(file)) || {}
          raise 'Structure of config file is not valid, has to be a Hash' if !config.kind_of?(Hash)
          config.each do |key, value|
            case key
            when *Webgen::Configuration::Helpers.public_instance_methods(false).map(&:to_s) then @config.send(key, value)
            else @config[key] = value
            end
          end
        rescue RuntimeError, ArgumentError => e
          raise ConfigFileInvalid, "Configuration invalid: " + e.message
        end
      elsif File.exists?(File.join(@directory, 'config.yml'))
        log(:warn) { "No configuration file called config.yaml found (there is a config.yml - spelling error?)" }
      end
    end

  end

end
