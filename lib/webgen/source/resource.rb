require 'webgen/websiteaccess'
require 'webgen/source'

module Webgen::Source

  # This class is used to provide access to source provided by resources.
  class Resource

    include Webgen::WebsiteAccess

    # The glob specifying the resources.
    attr_reader :glob

    # Create a new resource source for the the +glob+.
    def initialize(glob)
      @glob = glob
    end

    # Return all paths associated with the resources identified by #glob.
    def paths
      if !defined?(@paths)
        stack = Stacked.new
        website.config['resources'].select {|name, infos| File.fnmatch(@glob, name)}.sort.each do |name, infos|
          stack.add([['/', constant(infos.first).new(*infos[1..-1])]])
        end
        @paths = stack.paths
      end
      @paths
    end

  end

end
