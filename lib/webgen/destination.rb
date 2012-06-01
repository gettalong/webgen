# -*- encoding: utf-8 -*-

require 'webgen/common'
require 'webgen/error'

module Webgen

  # Namespace for all classes that are used to write content to a specific destination.
  #
  # == About this class
  #
  # This class is used to manage destination classes. A destination class is a class that writes
  # content to a specific destination. For example, the FileSystem class uses the file system to
  # write out the generated content.
  #
  # The #register method is used for registering new destination classes.
  #
  # Since there can only be one destination class per website instance, this manager class hides the
  # implementation details and uses the configuration option "destination" to create a new object
  # from the correct destination class. Use the #write, #read, #exists? and #delete methods on this
  # manager class to perform the equivalent operations on the destination class.
  #
  # == Implementing a destination class
  #
  # A destination class must respond to the following five methods:
  #
  # [<tt>initialize(website, *args)</tt>]
  #   The website instance is always provided as the first argument and the initialize method can
  #   have any number of other parameters.
  #
  # [<tt>exists?(path)</tt>]
  #   Return +true+ if the given path exists.
  #
  # [<tt>delete(path)</tt>]
  #   Delete the given path.
  #
  # [<tt>write(path, data)</tt>]
  #   Write the +data+ to the given +path+. If +path+ ends with a slash, a directory should be
  #   created. The parameter +data+ is either a String with the content or a Webgen::Path object. If
  #   it is the latter, use the Webgen::Path#io method for retrieving the IO object.
  #
  # [<tt>read(path, mode = 'rb')</tt>]
  #   Return the content of the given path if it exists or raise an error otherwise. The parameter
  #   +mode+ specifies the mode in which the path should be opened and defaults to reading in binary
  #   mode.
  #
  #   It seems a bit odd that a destination object has to implement reading functionality. However,
  #   consider the case where you want webgen to render a website programmatically and *use* the
  #   generated data. In this case you need a way to get the content of the generated files!
  #
  # == Sample destination class
  #
  # Following is a simple destination class which stores the written content in a hash in memory:
  #
  #   class MemoryDestination
  #
  #     attr_reader :data
  #
  #     def initialize(website)
  #       # the website object is not used in this destination class
  #       @data = {}
  #     end
  #
  #     def exists?(path)
  #       @data.has_key?(path)
  #     end
  #
  #     def delete(path)
  #       @data.delete(path)
  #     end
  #
  #     def write(path, data)
  #       @data[path] = (data.kind_of?(String) ? data : data.data)
  #     end
  #
  #     def read(path, mode = 'rb')
  #       raise "No such path #{path}" unless @data[path] && path[-1] != ?/
  #       @data[path]
  #     end
  #   end
  #
  #   website.ext.destination.register MemoryDestination, :name => 'memory'
  #
  class Destination

    include Webgen::Common::ExtensionManager

    # Create a new Destination object that is associated with the given website.
    def initialize(website)
      super()
      @website = website
    end

    # Register a destination class. The parameter +klass+ has to contain the name of the destination
    # class or the class object itself. If the class is located under this namespace, only the class
    # name without the hierarchy part is needed, otherwise the full class name including parent
    # module/class names is needed.
    #
    # === Options:
    #
    # [:name] The name for the destination class. If not set, it defaults to the snake-case version
    #         (i.e. FileSystem → file_system) of the class name (without the hierarchy part). It
    #         should only contain letters.
    #
    # [:author] The author of the destination class.
    #
    # [:summary] A short description of the destination class.
    #
    # === Examples:
    #
    #   destination.register('FileSystem')   # registers Webgen::Destination::FileSystem
    #
    #   destination.register('::FileSystem') # registers FileSystem !!!
    #
    #   destination.register('MyModule::Doit', name: 'doit_now')
    #
    def register(klass, options={}, &block)
      do_register(klass, options, false, &block)
    end

    # Return the instance of the configured destination class.
    def instance
      if !defined?(@instance)
        name, *args = @website.config['destination']
        @instance = extension(name).new(@website, *args)
      end
      @instance
    end
    private :instance

    # Return +true+ if the given path exists.
    def exists?(path)
      instance.exists?(path)
    end

    # Delete the given +path+
    def delete(path)
      instance.delete(path)
    end

    # Write the +data+ (either a String or a Webgen::Path object) to the given +path+.
    def write(path, data)
      instance.write(path, data)
    end

    # Return the content of the given +path+ which is opened in +mode+.
    def read(path, mode = 'rb')
      instance.read(path, mode)
    end

  end

end
