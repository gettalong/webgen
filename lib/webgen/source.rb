# -*- encoding: utf-8 -*-

require 'webgen/extension_manager'
require 'webgen/path'

module Webgen

  # Namespace for all classes that provide source paths.
  #
  # == About this class
  #
  # This class is used to manage source classes. A source class is a class that returns a set of
  # Path objects when the <tt>\#paths</tt> method is called. For example, the FileSystem class uses
  # the file system as the source for the source paths.
  #
  # The #register method is used for registering new source classes.
  #
  # To get all configured source paths, use the #paths method of this class.
  #
  # Extension writers may be interested in the #passive_sources accessor which allows one to
  # register sources that provide paths that are only used when actually referenced.
  #
  # == Implementing a source class
  #
  # A source class only needs to respond to the method +paths+ which needs to return a set of Path
  # objects for the source. It is expected that after a source object is initialized it always
  # returns the same path objects. The +initialize+ method of a source class must take the website
  # object as first argument and may take an arbitrary number of additional arguments.
  #
  # Note that the returned Path objects need to have the meta information <tt>modified_at</tt> set
  # to the correct last modification time of the path, i.e. the value has to be a Time object! This
  # is needed to determine whether the content of the path has been changed since the last
  # invocation of webgen.
  #
  # == Sample source class
  #
  # Following is a simple source class which stores the paths and their contents in a hash:
  #
  #   require 'stringio'
  #   require 'set'
  #   require 'webgen/path'
  #
  #   class MemorySource
  #
  #     CONTENT = {
  #       '/directory/' => nil,
  #       '/directory/file.page' => "This is the content of the file"
  #     }
  #
  #     def initialize(website, data = {})
  #       @data = data
  #     end
  #
  #     def paths
  #       CONTENT.merge(@data).collect do |path, content|
  #         Webgen::Path.new(path, path, 'modified_at' => Time.now) { StringIO.new(content.to_s) }
  #       end.to_set
  #     end
  #
  #   end
  #
  #   website.ext.source.register MemorySource, :name => 'memory'
  #
  class Source

    include Webgen::ExtensionManager


    # An array with one or more passive source definitions (a source definition is an array
    # containing a mount point, the short name for a Source class and its arguments).
    #
    # The paths read from these sources will automatically be tagged with the 'passive' meta
    # information key so that they are only used when referenced.
    #
    # This is very useful for providing templates, images and other paths in webgen extensions that
    # should only be rendered when actually being referenced.
    attr_reader :passive_sources


    # Create a new source manager object for the given website.
    def initialize(website)
      super()
      @website = website
      @passive_sources = []
    end

    # Register a source class. The parameter +klass+ has to contain the name of the source class or
    # the class object itself. If the class is located under this namespace, only the class name
    # without the hierarchy part is needed, otherwise the full class name including parent
    # module/class names is needed.
    #
    # === Options:
    #
    # [:name] The name for the source. If not set, it defaults to the snake-case version (i.e.
    #         FileSystem → file_system) of the class name (without the hierarchy part). It should
    #         only contain letters.
    #
    # [:author] The author of the source class.
    #
    # [:summary] A short description of the source class.
    #
    # === Examples:
    #
    #   source.register('FileSystem')   # registers Webgen::Source::FileSystem
    #
    #   source.register('::FileSystem') # registers FileSystem !!!
    #
    #   source.register('MyModule::Doit', name: 'my_doit')
    #
    def register(klass, options={}, &block)
      do_register(klass, options, false, &block)
    end

    # Return all configured source paths.
    #
    # The source paths are taken from the sources specified in the "sources" and the
    # "sources.passive" configuration options. All paths that additionally match one of the
    # "sources.ignore_paths" patterns are ignored.
    def paths
      if !defined?(@paths)
        active_source = extension('stacked').new(@website, @website.config['sources'].collect do |mp, name, *args|
                                                   [mp, extension(name).new(@website, *args)]
                                                 end)
        passive_source = extension('stacked').new(@website, @passive_sources.collect do |mp, name, *args|
                                                    [mp, extension(name).new(@website, *args)]
                                                  end)
        passive_source.paths.each {|path| path['passive'] = true}
        source = extension('stacked').new(@website, [['/', active_source], ['/', passive_source]])

        @paths = {}
        source.paths.each do |path|
          if !(@website.config['sources.ignore_paths'].any? {|pat| Webgen::Path.matches_pattern?(path, pat)})
            @paths[path.path] = path
          end
        end
      end
      @paths
    end

  end

end
