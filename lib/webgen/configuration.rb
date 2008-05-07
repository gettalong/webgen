module Webgen

  class Configuration

    class MethodChain

      def initialize(config)
        @config = config
        @name = ''
      end

      def method_missing(id, *args)
        @name += (@name.empty? ? '' : '.') + id.id2name.sub(/(!|=)$/,'')
        if args.length > 0
          value = args.shift
          @config.data[@name] = value unless @config.data.has_key?(@name) # value is set only the first time
          (@config.options[@name] ||= {}).update(*args) if args.length > 0
          nil
        else
          self
        end
      end

    end

    attr_reader :options
    attr_reader :data

    def initialize
      @data = {}
      @options = {}
    end

    def [](name)
      if @data.has_key?(name)
        @data[name]
      else
        raise ArgumentError, "No such configuration option: #{name}"
      end
    end

    def []=(name, value)
      if @data.has_key?(name)
        @data[name] = value
      else
        raise ArgumentError, "No such configuration option: #{name}"
      end
    end

    def method_missing(id, *args)
      MethodChain.new(self).method_missing(id, *args)
    end

  end

end
