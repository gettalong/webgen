module Webgen

  class Cache

    def initialize()
      @old_data = {}
      @new_data = {}
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
      @old_data = data
    end

    def dump
      @old_data.merge(@new_data)
    end

    def instance(name, *args, &block)
      self[[:class, name]] ||= constant(name).new(*args, &block)
    end

  end

end
