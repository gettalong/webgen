# -*- encoding: utf-8 -*-

require 'webgen/source'
require 'webgen/common'

module Webgen
  class Source

    # This class is used to provide access to sources provided by resources.
    class Resource

      # The glob (see File.fnmatch) specifying the resources.
      attr_reader :glob

      # The glob (see File.fnmatch) specifying the paths that should be used from the resources.
      attr_reader :paths_glob

      # The prefix that should optionally be stripped from the paths.
      attr_reader :strip_prefix

      # Create a new resource source for the the +glob+ and use only those paths matching +paths_glob+
      # while stripping +strip_prefix+ off the path.
      def initialize(glob, paths_glob = nil, strip_prefix = nil)
        @glob, @paths_glob, @strip_prefix = glob, paths_glob, strip_prefix
      end

      # Return all paths associated with the resources identified by #glob.
      def paths
        if !defined?(@paths)
          stack = Stacked.new
          #TODO: resources need to be defined in another way, not via the configuration mechanism
          website.config['resources'].select {|name, infos| File.fnmatch(@glob, name)}.sort.each do |name, infos|
            stack.add([['/', Webgen::Common.const_for_name(infos.first).new(*infos[1..-1])]])
          end
          @paths = stack.paths
          @paths = @paths.select {|p| File.fnmatch(@paths_glob, p)} if @paths_glob
          @paths.collect! {|p| p.mount_at('/', @strip_prefix)} if @strip_prefix
        end
        @paths
      end

    end

  end
end
