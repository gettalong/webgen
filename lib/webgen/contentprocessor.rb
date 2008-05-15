module Webgen

  module ContentProcessor

    autoload :Context, 'webgen/contentprocessor/context'
    autoload :Maruku, 'webgen/contentprocessor/maruku'
    autoload :Tags, 'webgen/contentprocessor/tags'

    def self.list
      WebsiteAccess.website.config['contentprocessor.map'].keys
    end

    def self.for_name(name)
      klass = WebsiteAccess.website.config['contentprocessor.map'][name]
      klass.nil? ? nil : WebsiteAccess.website.cache.instance(klass)
    end

  end

end
