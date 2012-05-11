# -*- encoding: utf-8 -*-

##
# Welcome to the API documentation of wegen!
#
# Have a look at the Webgen module which provides a good starting point!


# Standard lib requires
require 'logger'
require 'stringio'
require 'fileutils'
require 'ostruct'
require 'rbconfig'

# Requirements for Website
require 'webgen/core_ext'
require 'webgen/configuration'
require 'webgen/blackboard'
require 'webgen/cache'
require 'webgen/error'
require 'webgen/tree'
require 'webgen/extension_loader'

# Load other needed files
require 'webgen/path'
require 'webgen/node'
require 'webgen/page'
require 'webgen/version'


# TODO: adapt this documentation
#
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
#
# == General information
#
# Here are some detail on the internals of webgen that will help you while developing for webgen:
#
# * webgen uses a not so complex system for determining whether a node needs to be recreated or
#   re-rendered. However, for this to work correctly all extensions have to follow some rules:
#
#   * It is necessary that all node alcns from which the content is used are put into the
#     destination node's <tt>node_info[:used_nodes]</tt> set.
#
#   * It is necessary that all other node alcns that are used for a node in any way, even if they
#     are only referenced or the route to their output path used, have to be put into the node's
#     <tt>node_info[:used_meta_info_nodes]</tt> set.
#
# * Any node that is created during the rendering phase, ie. via a content processor, a tag or in
#   the #content method of a source handler needs to be put into the rendered node's
#   <tt>node_info[:used_meta_info_nodes]</tt> or <tt>node_info[:used_nodes]</tt> set (see above for
#   details)! This is especially necessary when using resolved nodes since resolved nodes can be
#   created by passive sources!
#
# * webgen provides various Error classes. However, errors should only be raised if additional runs
#   won't correct the problem. For example, if a path cannot be resolved, it is possible that in the
#   next run a node will be created and that the path can be resolved then. This is always the case,
#   for example, with fragment nodes! In such cases an error message should be written out to the
#   log to inform the user that there is a potential problem.
#
# == Blackboard services
#
# The Blackboard class provides an easy communication facility between objects by implementing the
# Observer pattern.
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
      @@data_dir = File.expand_path(File.join(RbConfig::CONFIG["datadir"], "webgen")) if !File.exists?(@@data_dir)
      raise "Could not find webgen data directory! This is a bug, report it please!" unless File.directory?(@@data_dir)
    end
    @@data_dir
  end


  # TODO: update!!!
  #
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

    # The website configuration. Can only be used after #init has been called (which is
    # automatically done in #render).
    attr_reader :config

    # The blackboard used for inter-object communication. Can only be used after #init has been
    # called.
    attr_reader :blackboard

    # A cache to store information that should be available between runs. Can only be used after
    # #init has been called.
    attr_reader :cache

    # Access to all extension objects.
    attr_reader :ext

    # The internal data structure used to store information about individual nodes.
    attr_reader :tree

    # The logger used for logging.
    attr_reader :logger

    # The website directory.
    attr_reader :directory

    # Create a new webgen Website object for the website in the directory +dir+ and initialize it
    # (calls #init).
    #
    # If no logger is specified, a dummy logger that logs to a StringIO is created.
    #
    # You can provide a block for modifying the Website object in any way during the initialization.
    # If the block only takes one parameter, it is called with the Website object after the
    # initialization is done. If it takes two parameters, the first one is the Website object and
    # the second one is a boolean specifying whether the block is currently called before the
    # initialization (value is +true+) or after it (value is +false).
    def initialize(dir, logger = nil, &block)
      @directory = dir
      @logger = logger || Logger.new(StringIO.new)
      @init_block = block
      init
    end

    # Initialize the configuration, blackboard and cache objects and load the default configuration
    # as well as website specific extensions.
    def init
      @tree = Tree.new(self)
      @blackboard = Blackboard.new
      @config = Configuration.new
      @cache = nil
      @ext = OpenStruct.new

      @init_block.call(self, true) if @init_block && @init_block.arity == 2
      load_extensions
      load_configuration
      if @init_block
        @init_block.arity == 1 ? @init_block.call(self) : @init_block.call(self, false)
      end
      @config.freeze

      restore_cache
      @blackboard.dispatch_msg(:website_initialized)
    end
    private :init

    # Load all extension files.
    #
    # This loads the extension file for the shipped extensions as well as all website specific
    # extensions.
    def load_extensions
      ext_dir = File.join(@directory, 'ext')
      ext_loader = ExtensionLoader.new(self, ext_dir)
      ext_loader.load('webgen/extensions')
      Dir[File.join(ext_dir, '**/init.rb')].sort.each {|file| ext_loader.load(file[ext_dir.length..-1])}
      ext_loader.load('init.rb') if File.file?(File.join(ext_dir, 'init.rb'))
    end
    private :load_extensions

    # Load the configuration file into the Configuration object.
    def load_configuration
      config_file = File.join(@directory, 'config.yaml')
      if File.exist?(config_file)
        @config.load_from_file(config_file)
        @logger.debug { "Configuration data loaded from <#{config_file}>" }
      end
    end
    private :load_configuration

    def restore_cache
      @cache = Cache.new
      data = if config['website.cache'].first == :file
               cache_file = File.absolute_path(config['website.cache'].last, @directory)
               File.binread(cache_file) if File.exists?(cache_file)
             else
               config['website.cache'].last
             end
      cache_data, version = Marshal.load(data) rescue nil
      @cache.restore(cache_data) if cache_data && version == Webgen::VERSION
    end
    private :restore_cache

    # Generate the website.
    def generate
      successful = @ext.path_handler.generate_website
      save_cache if successful
      successful
    end

    # Save the +cache+ to +website.cache+.
    def save_cache
      cache_data = [@cache.dump, Webgen::VERSION]
      if config['website.cache'].first == :file
        cache_file = File.absolute_path(config['website.cache'].last, @directory)
        File.open(cache_file, 'wb') {|f| Marshal.dump(cache_data, f)}
      else
        config['website.cache'][1] = Marshal.dump(cache_data)
      end
    end
    private :save_cache

    # TODO: extract this method into a new Task extension. The website then just has an execute
    # method that is given a task name and optional arguments.
    #
    # Clean the website directory from all generated output files (including the cache file). If
    # +del_outdir+ is +true+, then the base output directory is also deleted. When a delete
    # operation fails, the error is silently ignored and the clean operation continues.
    #
    # Note: Uses the configured output instance for the operations!
    def clean(del_outdir = false)
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

end
