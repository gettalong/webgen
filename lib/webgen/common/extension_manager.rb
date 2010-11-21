# -*- encoding: utf-8 -*-

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
      # **Note** that this method has to be implemented by classes that include this module.
      # Normally, it registers one or more names for an extension object by associating the names
      # for the extension object data via the <tt>@extensions</tt> hash.
      def register(*args, &block)
        raise NotImplementedError
      end

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
