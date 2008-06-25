require 'webgen/websiteaccess'

module Webgen

  # This module should be included in all classes that need a logging facility.
  module Loggable

    # Log the result of the +block+ using the log level +log_level+.
    def log(sev_level, &block)
      source = (self.kind_of?(Class) ? self.name : self.class.name) + '#' + caller[0][%r"`.*"][1..-2]
      if WebsiteAccess.website && WebsiteAccess.website.logger && (!WebsiteAccess.website.config['logger.mask'] || source =~ WebsiteAccess.website.config['logger.mask'])
        WebsiteAccess.website.logger.send(sev_level, source, &block)
      end
    end

  end

end
