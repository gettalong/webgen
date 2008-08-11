require 'webgen/websiteaccess'
require 'webgen/tag'
require 'cgi'

module Webgen::Tag

  # Includes a file verbatim and optionally escapes all special HTML characters and processes webgen
  # tags in it.
  class IncludeFile

    include Webgen::Tag::Base
    include Webgen::WebsiteAccess

    def initialize #:nodoc:
      website.blackboard.add_listener(:node_changed?, method(:node_changed?))
    end

    # Include the specified file verbatim in the output, optionally escaping special HTML characters
    # and processing tags in it.
    def call(tag, body, context)
      filename = param('tag.includefile.filename')
      filename = File.join(website.directory, filename) unless filename =~ /^(\/|\w:)/
      content = File.open(filename, 'rb') {|f| f.read}
      content = CGI::escapeHTML(content) if param('tag.includefile.escape_html')
      (context.dest_node.node_info[:tag_includefile_filenames] ||= []) << [filename, File.mtime(filename)]

      [content, param('tag.includefile.process_output')]
    end

    #######
    private
    #######

    def node_changed?(node)
      if filenames = node.node_info[:tag_includefile_filenames]
        node.dirty = true if filenames.any? {|f, mtime| File.mtime(f) > mtime}
      end
    end

  end

end
