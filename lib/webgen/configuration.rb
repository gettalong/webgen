module Webgen

  # Stores the configuration for a webgen website.
  #
  # Configuration options should be created like this:
  #
  #   config.my.new.config 'value', :doc => 'some', :meta => 'info'
  #
  # and later accessed or set using the accessor methods #[] and #[]= or a configuration
  # helper. These helpers are defined in the Helpers module and provide easier access to complex
  # configuration options.
  class Configuration

    # Helper class for providing an easy method to define configuration options.
    class MethodChain

      def initialize(config) #:nodoc:
        @config = config
        @name = ''
      end

      def method_missing(id, *args) #:nodoc:
        @name += (@name.empty? ? '' : '.') + id.id2name.sub(/(!|=)$/,'')
        if args.length > 0
          value = args.shift
          @config.data[@name] = value unless @config.data.has_key?(@name) # value is set only the first time
          @config.meta_info[@name] ||= {}
          @config.meta_info[@name].update(*args) if args.length > 0
          nil
        else
          self
        end
      end

    end

    # This module provides methods for setting more complex configuration options. It is mixed into
    # Webgen::Configuration so that it methods can be used. Detailed information on the use of the
    # methods can be found in the "User Manual" in the "Configuration File" section.
    #
    # All public methods defined in this module are available for direct use in the
    # configuration file, e.g. the method named +default_meta_info+ can be used like this:
    #
    #   default_meta_info:
    #     Webgen::SourceHandler::Page:
    #       in_menu : true
    #       :action : replace
    #
    # All methods have to take exactly one argument, a Hash.
    #
    # The special key <tt>:action</tt> should be used for specifying how the configuration option
    # should be set:
    #
    #   replace::  Replace the configuration option with the new values.
    #   modify::   Replace old values with new values and add missing ones (useful for hashes and
    #              normally the default value)
    module Helpers

      # Set the default meta information for source handlers.
      def default_meta_info(args)
        args.each do |sh_name, mi|
          raise ArgumentError, 'Invalid argument for configuration helper default_meta_info' unless mi.kind_of?(Hash)
          action = mi.delete(:action) || 'modify'
          mi_hash = (self['sourcehandler.default_meta_info'][complete_source_handler_name(sh_name)] ||= {})
          case action
          when 'replace' then mi_hash.replace(mi)
          else mi_hash.update(mi)
          end
        end
      end


      # Set the path patterns used by source handlers.
      def patterns(args)
        args.each do |sh_name, data|
          pattern_arr = (self['sourcehandler.patterns'][complete_source_handler_name(sh_name)] ||= [])
          case data
          when Array then pattern_arr.replace(data)
          when Hash
            (data['del'] || []).each {|pat| pattern_arr.delete(pat)}
            (data['add'] || []).each {|pat| pattern_arr << pat}
          else
            raise ArgumentError, 'Invalid argument for configuration helper patterns'
          end
        end
      end

      # Complete +sh_name+ by checking if a source handler called
      # <tt>Webgen::SourceHandler::SH_NAME</tt> exists.
      def complete_source_handler_name(sh_name)
        (Webgen::SourceHandler.constants.include?(sh_name) ? 'Webgen::SourceHandler::' + sh_name : sh_name)
      end
      private :complete_source_handler_name
    end

    include Helpers

    # The hash which stores the meta info for the configuration options.
    attr_reader :meta_info

    # The configuration options hash.
    attr_reader :data

    # Create a new Configuration object.
    def initialize
      @data = {}
      @meta_info = {}
    end

    # Return the configuration option +name+.
    def [](name)
      if @data.has_key?(name)
        @data[name]
      else
        raise ArgumentError, "No such configuration option: #{name}"
      end
    end

    # Set the configuration option +name+ to the provided +value+.
    def []=(name, value)
      if @data.has_key?(name)
        @data[name] = value
      else
        raise ArgumentError, "No such configuration option: #{name}"
      end
    end

    def method_missing(id, *args) #:nodoc:
      MethodChain.new(self).method_missing(id, *args)
    end

  end

end
