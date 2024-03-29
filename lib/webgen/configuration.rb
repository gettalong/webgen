# -*- encoding: utf-8 -*-

require 'yaml'
require 'webgen/error'
require 'webgen/utils'

module Webgen

  # Stores the configuration for a webgen website.
  #
  # Configuration options can be created by using the define_option method:
  #
  #   config.define_option "my.new.option", 'default value'
  #
  # and later accessed or set using the accessor methods #[] and #[]=. A validation block can also
  # be specified when defining an option. This validation block is called when a new value should be
  # set and it should return the (possibly changed) value to be set:
  #
  #   config.define_option "my.new.option", 'default value' do |val|
  #     raise "Option must be a string" unless val.kind_of?(String)
  #     val.upcase
  #   end
  #
  # **Note**: When a Configuration object is dumped (via Marshal), the option validator procs are
  # not dumped and can therefore not be restored!
  class Configuration

    # Raised by the Webgen::Configuration class.
    class Error < Webgen::Error; end

    # Struct class for storing a configuration option.
    Option = Struct.new(:default, :validator) do
      def dupped_default #:nodoc:
        default.dup rescue default
      end

      def ==(other) #:nodoc:
        self.default == other.default
      end

      def marshal_dump #:nodoc:
        self.default
      end

      def marshal_load(data) #:nodoc:
        self.default = data
      end

    end


    # Contains all the defined configuration options.
    attr_reader :options

    # Create a new Configuration object.
    def initialize
      @options = {}
      @values = {}
    end

    def initialize_copy(orig) #:nodoc:
      super
      @options = orig.options.dup
      @values = {}
      orig.instance_eval { @values }.each {|k,v| @values[k] = v.dup rescue v}
    end

    def clone #:nodoc:
      super
      freeze if frozen?
    end

    def freeze #:nodoc:
      super
      @options.freeze
      @values.each_value {|v| v.freeze}
      @values.freeze
      self
    end

    def ==(other) #:nodoc:
      @options == other.options && @values == other.instance_variable_get(:@values)
    end

    # Define a new option +name+ with a default value of +default+.
    #
    # If a validation block is provided, it is called with the new value when one is set and should
    # return a (possibly altered) value to be set.
    def define_option(name, default, &validator)
      if @options.has_key?(name)
        raise ArgumentError, "Configuration option '#{name}' has already be defined"
      else
        @options[name] = Option.new
        @options[name].default = default.freeze
        @options[name].validator = validator.freeze
        @options[name].freeze
      end
    end

    # Return +true+ if the given option exists.
    def option?(name)
      @options.has_key?(name)
    end

    # Return the value for the configuration option +name+.
    def [](name)
      if @options.has_key?(name)
        if frozen?
          @values.has_key?(name) ? @values[name] : @options[name].dupped_default
        else
          @values[name] = @options[name].dupped_default unless @values.has_key?(name)
          @values[name]
        end
      else
        raise Error, "Configuration option '#{name}' does not exist"
      end
    end

    # Use +value+ as value for the configuration option +name+.
    def []=(name, value)
      if @options.has_key?(name)
        begin
          @values[name] = (@options[name].validator ? @options[name].validator.call(value) : value)
        rescue
          raise Error, "Problem setting configuration option '#{name}': #{$!.message}", $!.backtrace
        end
      else
        raise Error, "Configuration option '#{name}' does not exist"
      end
    end

    # Set the configuration values from the Hash +values+.
    #
    # The hash can either contain full configuration option names or namespaced option names, ie. in
    # YAML format:
    #
    #   my.option: value
    #
    #   website:
    #     lang: en
    #     url: my_url
    #
    # The above hash will set the option 'my.option' to +value+, 'website.lang' to +en+ and
    # 'website.url' to +my_url+.
    #
    # Returns an array with all unknown configuration options.
    def set_values(values)
      unknown_options = []
      process = proc do |name, value|
        if @options.has_key?(name)
          self[name] = value
        elsif value.kind_of?(Hash)
          value.each {|k,v| process.call("#{name}.#{k}", v)}
        else
          unknown_options << name
        end
      end
      values.each(&process)
      unknown_options
    end

    # Load the configuration values.
    #
    # If +filename+ is a String, it is treated as the name of the configuration file from which the
    # values should be loaded. If +filename+ responds to \#read, it is treated as an IO object from
    # which the values should be loaded.
    #
    # The configuration needs to be in YAML format. More specifically, it needs to contain a YAML
    # hash which is further processed by #set_values.
    #
    # Returns an array with all unknown configuration options.
    def load_from_file(filename)
      data = if String === filename || filename.respond_to?(:read)
               begin
                 Utils.yaml_load(String === filename ? File.read(filename) : filename.read) || {}
               rescue RuntimeError, ArgumentError, SyntaxError, YAML::SyntaxError => e
                 raise Error, "Problem parsing configuration data (it needs to contain a YAML hash): #{e.message}", e.backtrace
               end
             else
               raise ArgumentError, "Need a String or IO object, not a #{filename.class}"
             end
      raise Error, 'Structure of configuration file is invalid, it has to be a Hash' unless data.kind_of?(Hash)
      set_values(data)
    end

  end

end
