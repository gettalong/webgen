# -*- encoding: utf-8 -*-

require 'webgen/source'
require 'set'

module Webgen
  class Source

    # This source class is used to stack several sources together.
    #
    # It serves two purposes:
    #
    # * First, it can be used to access more than one source. This is useful when your website
    #   consists of more than one source directory and you want to use all of them.
    #
    # * Second, sources can be mounted on specific directories. For example, a folder with images
    #   that you don't want to copy to the main website source directory can be mounted under
    #   '/images' so that they are available nonetheless.
    #
    # Also be aware that when a path is returned by a source that has already be returned by a prior
    # source, it is discarded and not used.
    class Stacked

      # Return the stack of [mount point, source object] entries.
      attr_reader :stack

      # Create a new stack.
      #
      # The optional +map+ parameter is used to provide mappings of mount points to source objects.
      # It should be an array of two-element arrays which contain an absolute directory (ie.
      # starting and ending with a slash) and a source object.
      def initialize(website, map = {})
        @stack = []
        map.each do |mp, source|
          raise "Invalid mount point specified: #{mp}" unless mp =~ /^\//
          @stack << [mp, source]
        end
      end

      # Return all paths returned by the sources in the stack.
      #
      # Since the stack is ordered, paths returned by later source objects are not used if a prior
      # source object has returned the same path.
      def paths
        if !defined?(@paths)
          @paths = Set.new
          @stack.each do |mp, source|
            source.paths.each do |path|
              @paths.add?(path.mount_at(mp))
            end
          end
        end
        @paths
      end

    end

  end
end
