# -*- encoding: utf-8 -*-

require 'ostruct'
require 'webgen/utils'
require 'webgen/error'

module Webgen

  # Provides common functionality for extension manager classes.
  #
  # This module is intended for mixing into an extension manager class. An example for an extension
  # manage class is the Webgen::ContentProcessor class which manages all content processors.
  # Extension manager classes provide methods for registering a certain type of extension and
  # invoking methods on them via a common interface.
  #
  # It is assumed that one wants to associate one or more names with an extension object.
  module ExtensionManager

    # Create a new extension manager.
    def initialize
      @extensions = {}
    end

    def initialize_copy(orig) #:nodoc:
      super
      @extensions = {}
      orig.instance_eval { @extensions }.each {|k,v| @extensions[k] = v.clone}
    end

    # Register a new extension.
    #
    # **Note** that this method has to be implemented by classes that include this module. It should
    # register one or more names for an extension object by associating the names with the extension
    # object data (should be an object that responds at least to :object) via the @extensions hash.
    #
    # The simplest way to achieve this is to use the #do_register method.
    def register(klass, options = {}, &block)
      raise NotImplementedError
    end

    # Automatically perform the necessary steps to register the extension +klass+. This involves
    # normalization of the class name and associating the extension name (derived from the class
    # name if not set via the key :name in the options hash) with the extension.
    #
    # The parameter +klass+ can either be a String or a Class specifying the class that should be
    # registered.
    #
    # The parameter +options+ allows to associate additional information with an extension. The only
    # recognized key is :name (for the extension name). All other keys are ignored and can/should be
    # used by the extension manager class itself.
    #
    # The parameter +allow_block+ specifies whether the extension manager allows blocks as
    # extensions. If this parameter is +true+ and a block is provided, the +klass+ parameter is
    # not used!
    #
    # Returns the (possibly automatically generated) name for the extension.
    def do_register(klass, options = {}, allow_block = true, &block)
      if !allow_block && block_given?
        raise ArgumentError, "The extension manager '#{self.class.name}' does not support blocks on #register"
      end
      klass, klass_name = normalize_class_name(klass, !block_given?)
      name = (options[:name] || Webgen::Utils.snake_case(klass_name)).to_sym
      @extensions[name] = OpenStruct.new(:object => (block_given? ? block : klass))
      name
    end
    private :do_register

    # Return a complete class name (including the hierarchy part) based on +klass+ and the class
    # name without the hierarchy part.
    #
    # If the parameter +do_autoload+ is +true+ and the +klass+ is defined under this class, it is
    # autoloaded by turning the class name into a path name (See Webgen::Utils.snake_case).
    def normalize_class_name(klass, do_autoload = true)
      klass = (klass.kind_of?(Class) || klass.include?('::') ? klass : "#{self.class.name}::#{klass}")
      klass_name = klass.to_s.split(/::/).last
      if do_autoload && klass.to_s.start_with?(self.class.name) && klass_name =~ /^[A-Z]/
        self.class.autoload(klass_name.to_sym, Webgen::Utils.snake_case(klass.to_s))
      end
      [klass, klass_name]
    end
    private :normalize_class_name

    # Return the registered object for the extension +name+.
    #
    # This method also works in the case that +name+ is a String referencing a class. The method
    # assumes that @extensions[name] is an array where the registered object is the first element!
    def extension(name)
      raise Webgen::Error.new("No extension called '#{name}' registered for the '#{self.class.name}' extension manager") unless registered?(name)
      name = name.to_sym
      ext = @extensions[name].object
      ext.kind_of?(String) ? @extensions[name].object = resolve_class(ext) : ext
    end
    private :extension

    # Return the extension data for the extension +name+.
    def ext_data(name)
      @extensions[name.to_sym]
    end
    private :ext_data

    # If +class_or_name+ is a String, it is taken as the name of a class and is resolved. Else
    # returns +class_or_name+.
    def resolve_class(class_or_name)
      String === class_or_name ? Webgen::Utils.const_for_name(class_or_name) : class_or_name
    end
    private :resolve_class

    # Return +true+ if an extension with the given name has been registered with this manager
    # class.
    def registered?(name)
      @extensions.has_key?(name.to_sym)
    end

    # Return the meta data of all extensions registered with this manager class.
    def registered_extensions
      @extensions.dup
    end

  end

end
