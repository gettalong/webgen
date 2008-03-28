module Webgen::Source

  class Stacked < Base

    attr_reader :stack

    def initialize(map = {})
      @stack = []
      add(map)
    end

    def add(maps)
      maps.each do |mp, source|
        raise "Invalid mount point specified: #{mp}" unless mp =~ /^\//
        @stack << [mp, source]
      end
    end

    def paths
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
