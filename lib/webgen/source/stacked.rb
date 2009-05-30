# -*- encoding: utf-8 -*-

module Webgen::Source

  # This source class is used to stack several sources together.
  #
  # It serves two purposes:
  #
  # * First, it can be used to access more than one source. This is useful when your website
  #   consists of more than one source directory and you want to use all of them.
  #
  # * Second, sources can be mounted on specific directories. For example, a folder with images that
  #   you don't want to copy to the website source directory can be mounted under <tt>/images</tt>
  #   sothat they are available nonetheless.
  #
  # Also be aware that when a path is returned by a source that has already be returned by a prior
  # source, it is discarded and not used.
  class Stacked

    # Return the stack of mount point to Webgen::Source object maps.
    attr_reader :stack

    # Specifies whether the result of #paths calls should be cached (default: +false+). If caching
    # is activated, new maps cannot be added to the stacked source anymore!
    attr_accessor :cache_paths

    # Create a new stack. The optional +map+ parameter can be used to provide initial mappings of
    # mount points to source objects (see #add for details). You cannot add other maps after a call
    # to #paths if +cache_paths+ is +true+
    def initialize(map = {}, cache_paths = false)
      @stack = []
      @cache_paths = cache_paths
      add(map)
    end

    # Add all mappings found in +maps+ to the stack. The parameter +maps+ should be an array of
    # two-element arrays which contain an absolute directory (ie. starting and ending with a slash)
    # and a source object.
    def add(maps)
      raise "Cannot add new maps since caching is activated for this source" if defined?(@paths) && @cache_paths
      maps.each do |mp, source|
        raise "Invalid mount point specified: #{mp}" unless mp =~ /^\//
        @stack << [mp, source]
      end
    end

    # Return all paths returned by the sources in the stack. Since the stack is ordered, paths
    # returned by later source objects are not used if a prior source object has returned the same
    # path.
    def paths
      return @paths if defined?(@paths) && @cache_paths
      @paths = Set.new
      @stack.each do |mp, source|
        source.paths.each do |path|
          @paths.add?(path.mount_at(mp))
        end
      end
      @paths
    end

  end

end
