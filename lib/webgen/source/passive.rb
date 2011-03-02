# -*- encoding: utf-8 -*-

require 'webgen/source'

module Webgen
  class Source

    # This source class marks all paths from the provided source object as passive.
    class Passive

      # Create a new Passive source object which marks the paths from +source+ as passive.
      def initialize(source)
        @source = source
      end

      # Return all paths as passive paths.
      def paths
        @source.paths.each {|path| path['no_output'] = true}
      end

    end

  end
end
