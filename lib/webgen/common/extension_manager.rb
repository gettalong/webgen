# -*- encoding: utf-8 -*-

require 'webgen/common'

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

      # The website instance to which this extension manager object belongs. Maybe +nil+ if it does
      # not belong to a website instance (for example, this is the case for the static extension
      # manager objects used by the webgen distribution itself).
      attr_accessor :website

      # Create a new extension manager.
      def initialize
        @extensions = {}
        @website = nil
      end

      def initialize_copy(orig) #:nodoc:
        super
        @extensions = {}
        orig.instance_eval { @extensions }.each {|k,v| @extensions[k] = v.clone}
      end

      # Register a new extension.
      #
      # **Note** that this method has to be implemented by classes that include this module.
      # Normally, it registers one or more names for an extension object by associating the names
      # for the extension object data via the <tt>@extensions</tt> hash.
      def register(klass, options = {}, &block)
        raise NotImplementedError
      end

      # Helper method for use in #register. Returns a complete class name (including the hierarchy
      # part) based on +klass+ and the class name without the hierarchy part.
      def get_defaults(klass, has_block)
        klass = (klass.include?('::') ? klass : "#{self.class.name}::#{klass}")
        klass_name = klass.split(/::/).last
        if !has_block && klass.start_with?(self.class.name) && klass_name =~ /^[A-Z]/
          autoload(klass_name.to_sym, Webgen::Common.snake_case(klass))
        end
        [klass, klass_name]
      end
      private :get_defaults

      # Return +true+ if an extension with the given name has been registered with this manager
      # class.
      def registered?(name)
        @extensions.has_key?(name.to_s)
      end

      # Return the names of all available extension names registered with this manager class.
      def registered_names
        @extensions.keys.sort
      end

      # This module can be used to extend an extension manager class. It provides access to a static
      # extension manager object on which extensions can be registered.
      module ClassMethods

        # Return the static extension manager object for the class.
        def static
          @static ||= self.new
          yield(@static) if block_given?
          @static
        end

        # See ExtensionManager#register.
        def register(*args, &block)
          static.register(*args, &block)
        end

      end

    end

  end

end
