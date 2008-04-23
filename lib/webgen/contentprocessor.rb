module Webgen

  module ContentProcessor

    autoload :Context, 'webgen/contentprocessor/context'
    autoload :Maruku, 'webgen/contentprocessor/maruku'

    def self.list
      WebsiteAccess.website.config['contentprocessors'].keys
    end

    def self.for_name(name)
      klass = WebsiteAccess.website.config['contentprocessors'][name]
      klass.nil? ? nil : WebsiteAccess.website.cache.instance(klass)
    end

  end

end
