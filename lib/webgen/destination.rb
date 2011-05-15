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
  # [<tt>write(path, data, type)</tt>]
  #   Write the +data+ to the given +path+. The parameter +data+ is either a String with the content
  #   or a Webgen::Path::SourceIO object. The parameter +type+ specifies the type of the to be
  #   written path: <tt>:file</tt> or <tt>:directory</tt>.
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
  #     def write(path, io, type = :file)
  #       @data[path] = [(io.kind_of?(String) ? io : io.data), type]
  #     end
  #
  #     def read(path, mode = 'rb')
  #       path = File.join('/', path)
  #       raise "No such file #{path}" unless @data[path] && @data[path].last == :file
  #       @data[path].first
  #     end
  #   end
  #
  #   website.ext.destination.register '::MemoryDestination'
  #
  class Destination

    include Webgen::Common::ExtensionManager

    # Create a new Destination object that is associated with the given website.
    def initialize(website)
      super()
      @website = website
    end

    # Register a destination class. The parameter +klass+ has to contain the name of the destination
    # class. If the class is located under this namespace, only the class name without the hierarchy
    # part is needed, otherwise the full class name including parent module/class names is needed.
    #
    # All other parameters can be set through the options hash if the default values aren't
    # sufficient.
    #
    # === Options:
    #
    # [:name] The name for the destination class. If not set, it defaults to the snake-case version
    #         (i.e. FileSystem → file_system) of the class name (without the hierarchy part). It
    #         should only contain letters.
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
      do_register(klass, options, [], false, &block)
    end

    # Return the instance of the configured destination class.
    #
    # **Note** that this method won't work if no website object is set!
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

    # Write the +data+ to the given +path+. The +type+ parameter specifies the type of the path to
    # be created which can either be <tt>:file</tt> or <tt>:directory</tt>.
    def write(path, data, type = :file)
      instance.write(path, data, type)
    end

    # Return the content of the given +path+ which is opened in +mode+.
    def read(path, mode = 'rb')
      instance.read(path, mode)
    end

  end

end
