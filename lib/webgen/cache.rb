module Webgen

  class Cache

    def initialize()
      @old_data = {}
      @new_data = {}
    end

    def [](key)
      @old_data[key]
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

  end

end
