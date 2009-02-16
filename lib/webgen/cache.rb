# -*- encoding: utf-8 -*-

require 'set'
require 'facets/kernel/constant'

module Webgen

  # A cache object provides access to various caches to speed up rendering of a website.
  #
  # permanent:: The permanent cache should be used for data that should be available between webgen
  #             runs.
  #
  # volatile:: The volatile cache is used for data that can easily be regenerated but might be
  #            expensive to do so. This cache is not stored between webgen runs.
  #
  # standard:: The standard cache saves data between webgen runs and returns the cached data (not
  #            the newly set data) if it is available. This is useful, for example, to store file
  #            modifcation times and check if a file has been changed between runs.
  #
  # The standard cache should be accessed through the <tt>[]</tt> method which returns the correct
  # value and the <tt>[]=</tt> method should be used for setting the new value. However, if you
  # really need to access a particular value of the old or new standard cache, you can use the
  # accessors +old_data+ and +new_data+.
  class Cache

    # The permanent cache hash.
    attr_reader :permanent

    # The volatile cache hash.
    attr_reader :volatile

    # The cache data stored in the previous webgen run.
    attr_reader :old_data

    # The cache data stored in the current webgen run.
    attr_reader :new_data

    # Create a new cache object.
    def initialize()
      @old_data = {}
      @new_data = {}
      @volatile = {}
      @permanent = {:classes => []}
    end

    # Return the cached data (or, if it is not available, the new data) identified by +key+ from the
    # standard cache.
    def [](key)
      if @old_data.has_key?(key)
        @old_data[key]
      else
        @new_data[key]
      end
    end

    # Store +value+ identified by +key+ in the standard cache.
    def []=(key, value)
      @new_data[key] = value
    end

    # Restore the caches from +data+ and recreate all cached instances (see #instance).
    def restore(data)
      @old_data, @permanent = *data
      @permanent[:classes].each {|klass| instance(klass)}
    end

    # Return all caches that should be available between webgen runs.
    def dump
      [@old_data.merge(@new_data), @permanent]
    end

    # Reset the volatile cache.
    def reset_volatile_cache
      @volatile = {:classes => @volatile[:classes]}
    end

    # Return the unique instance of the class +name+. This method should be used when it is
    # essential that webgen uses only one object of a class or when an object should automatically
    # be recreated upon cache restoration (see #restore).
    def instance(name)
      @permanent[:classes] << name unless @permanent[:classes].include?(name)
      (@volatile[:classes] ||= {})[name] ||= constant(name).new
    end

  end

end
