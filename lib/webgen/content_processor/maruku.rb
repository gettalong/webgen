# -*- encoding: utf-8 -*-

require 'webgen/content_processor'
require 'rexml/parsers/baseparser'
webgen_require 'maruku'


# :stopdoc:
# Fixes a problem when parsing Markdown with <webgen>-tags in Maruku.
class REXML::Parsers::BaseParser

  alias_method :"old_stream=", :"stream="

  def stream=(source)
    self.old_stream = source
    @nsstack << Set.new(['webgen'])
  end

end
# :startdoc:


module Webgen
  class ContentProcessor

    # Processes content in Markdown format using the +maruku+ library.
    module Maruku

      # Convert the content in +context+ to HTML.
      def self.call(context)
        $uid = 0 # fix for invalid fragment IDs on second run
        context.content = ::Maruku.new(context.content, :on_error => :raise).to_html
        context
      end

    end

  end
end
