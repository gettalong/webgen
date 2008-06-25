module Webgen

  # Stores the configuration for a webgen website.
  #
  # Configuration options should be created like this:
  #
  #   config.my.new.config 'value', :doc => 'some', :meta => 'info'
  #
  # and later accessed or set using the accessor methods #[] and #[]=.
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
