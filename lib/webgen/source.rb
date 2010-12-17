# -*- encoding: utf-8 -*-

require 'webgen/common'
require 'webgen/error'

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
  # == Implementing a source class
  #
  # A source class only needs to respond to the method +paths+ which needs to return a set of Path
  # objects for the source. The +initialize+ method of a source class may take an arbitrary number
  # of arguments.
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
  #     def initialize(data = {})
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
  #   website.ext.source.register '::MemorySource'
  #
  class Source

    include Webgen::Common::ExtensionManager
    extend ClassMethods

    # Register a source class. The parameter +klass+ has to contain the name of the class which
    # has to respond to +call+ or which has an instance method +call+. If the class is located under
    # this namespace, only the class name without the hierarchy part is needed, otherwise the full
    # class name including parent module/class names is needed. All other parameters can be set
    # through the options hash if the default values aren't sufficient.
    #
    # === Options:
    #
    # [:name] The name for the source. If not set, it defaults to the snake-case version (i.e.
    #         FileSystem → file_system) of the class name (without the hierarchy part). It should
    #         only contain letters.
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
      do_register(klass, options, [], false, &block)
    end

    # Return all configured source paths.
    #
    # The source paths are taken from the sources specified in the "sources" and the
    # "sources.passive" configuration options. All paths that additionally match one of the
    # "sources.ignore_paths" patterns are ignored.
    #
    # **Note** that this method won't work if no website object is set!
    def paths
      if !defined?(@paths)
        active_source = extension('stacked').new(website.config['sources'].collect do |mp, name, *args|
                                                   [mp, extension(name).new(*args)]
                                                 end)
        passive_source = extension('stacked').new(website.config['sources.passive'].collect do |mp, name, *args|
                                                    [mp, extension('passive').new(extension(name).new(*args))]
                                                  end)
        source = extension('stacked').new([['/', active_source], ['/', passive_source]])

        @paths = {}
        source.paths.each do |path|
          if !(website.config['sources.ignore_paths'].any? {|pat| File.fnmatch(pat, path, File::FNM_CASEFOLD|File::FNM_DOTMATCH)})
            @paths[path.source_path] = path
          end
        end
      end
      @paths
    end

    register "Stacked"
    register "Passive"
    register "FileSystem"
    register "Resource"
    register "TarArchive"

  end

end
