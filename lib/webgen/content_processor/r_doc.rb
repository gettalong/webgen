# -*- encoding: utf-8 -*-

require 'webgen/content_processor'

### Hack...
# Workaround to load the correct version of rdoc. Unusable versions don't have a rdoc/store file and
# so we can use this to our advantage.
begin
  # If a useable version is available, this won't fail with a LoadError (but probably a NameError)
  # and will activate the correct version, even if installed via Rubygems.
  require 'rdoc/store'
rescue LoadError
  webgen_require('rdoc/rdoc', 'rdoc')
rescue Exception
end
require 'rdoc/rdoc'


module Webgen
  class ContentProcessor

    # Converts content in RDoc markup (the native Ruby documentation format) to HTML. Needs the newer
    # RDoc implementation (version >= 4.0.0).
    module RDoc

      # Convert the content in RDoc markup to HTML.
      def self.call(context)
        context.content = ::RDoc::Markup::ToHtml.new(::RDoc::Options.new).convert(context.content)
        context
      end

    end

  end
end
