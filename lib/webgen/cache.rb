module Webgen

  class Cache

    attr_reader :permanent
    attr_reader :volatile

    def initialize()
      @old_data = {}
      @new_data = {}
      @volatile = {}
      @permanent = {}
    end

    def [](key)
      if @old_data.has_key?(key)
        @old_data[key]
      else
        @new_data[key]
      end
    end

    def []=(key, value)
      @new_data[key] = value
    end

    def restore(data)
      @old_data, @permanent = *data
      @permanent[:classes] && @permanent[:classes].each {|klass| instance(klass)}
    end

    def dump
      [@old_data.merge(@new_data), @permanent]
    end

    def instance(name)
      (@permanent[:classes] ||= Set.new) << name
      @volatile[[:class, name]] ||= constant(name).new
    end

  end

end
