require 'webgen/websiteaccess'
require 'webgen/sourcehandler/base'

module Webgen::SourceHandler

  # Source handler for creating atom or rss feeds.
  class Feed

    include Webgen::WebsiteAccess
    include Base

    # Create atom and/or rss feed files from +parent+ and +path+.
    def create_node(parent, path)
      page = page_from_path(path)

      super(parent, path) do |node|
        node.node_info[:page] = page
      end
    end

  end

end
