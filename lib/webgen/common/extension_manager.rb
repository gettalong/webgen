# -*- encoding: utf-8 -*-

require 'webgen/common'
require 'webgen/error'

module Webgen

  # Namespace for classes and methods that provide common functionality.
  module Common

    # Provides common functionality for extension manager classes.
    #
    # This module is intended for mixing into an extension manager class. For example, the
    # Webgen::ContentProcessor class manages all content processors. Extension manager classes
    # provide methods for registering a certain type of extension and invoking methods on them via a
    # common interface.
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
      # **Note** that this method has to be implemented by classes that include this module. It
      # should register one or more names for an extension object by associating the names with the
      # extension object data (should be an array where the first element is the extension object)
      # via the <tt>@extensions</tt> hash. See also #do_register.
      def register(klass, options = {}, &block)
        raise NotImplementedError
      end

      # Automatically perform the necessary steps to register the extension +klass+. This involves
      # normalization of the class name, retrieving the name for the extension from the +options+
      # hash and then associating the name with the extension. Also returns the (possibly
      # automatically generated) name for the extension.
      #
      # The parameter +fields+ can be used to add additional fields (in order of appearance; the
      # values are taken from the options hash) to the associated data array. The parameter
      # +allow_block+ specifies whether the extension manager allows blocks as extensions.
      def do_register(klass, options, fields = [], allow_block = true, &block)
        if !allow_block && block_given?
          raise ArgumentError, "The extension manager '#{self.class.name}' does not support blocks on #register"
        end
        klass, klass_name = normalize_class_name(klass)
        name = (options[:name] || Webgen::Common.snake_case(klass_name)).to_sym
        @extensions[name] = [(block_given? ? block : klass), *fields.map {|f| options[f]}]
        name
      end
      private :do_register

      # Return a complete class name (including the hierarchy part) based on +klass+ and the class
      # name without the hierarchy part. If the parameter +do_autoload+ is +true+ and the +klass+ is
      # defined under this class, it is autoloaded by turning the class name into a path name (See
      # Webgen::Common.snake_case).
      def normalize_class_name(klass, do_autoload = true)
        klass = (klass.include?('::') ? klass : "#{self.class.name}::#{klass}")
        klass_name = klass.split(/::/).last
        if do_autoload && klass.start_with?(self.class.name) && klass_name =~ /^[A-Z]/
          self.class.autoload(klass_name.to_sym, Webgen::Common.snake_case(klass))
        end
        [klass, klass_name]
      end
      private :normalize_class_name

      # Return the registered object for the extension +name+. This method also works in the case
      # that +name+ is a String referencing a class. The method assumes that
      # <tt>@extensions[name]</tt> is an array where the registered object is the first element!
      def extension(name)
        raise Webgen::Error.new("No extension called '#{name}' registered for the '#{self.class.name}' extension manager") unless registered?(name)
        name = name.to_sym
        ext = @extensions[name].first
        ext.kind_of?(String) ? @extensions[name][0] = resolve_class(ext) : ext
      end
      private :extension

      # If +class_or_name+ is a String, it is taken as the name of a class and is resolved. Else
      # returns +class_or_name+.
      def resolve_class(class_or_name)
        String === class_or_name ? Webgen::Common.const_for_name(class_or_name) : class_or_name
      end
      private :resolve_class

      # Return +true+ if an extension with the given name has been registered with this manager
      # class.
      def registered?(name)
        @extensions.has_key?(name.to_sym)
      end

      # Return the names of all available extension names registered with this manager class.
      def registered_names
        @extensions.keys.sort
      end

    end

  end

end
