# -*- encoding: utf-8 -*-

module Webgen

  # Namespace for all classes that provide source paths.
  #
  # == Implementing a source class
  #
  # Source classes provide access to the source paths on which the source handlers act.
  #
  # A source class only needs to respond to the method +paths+ which needs to return a set of paths
  # for the source. The returned paths must respond to the method <tt>changed?</tt> (has to return
  # +true+ if the paths has changed since the last webgen run). The default implementation in the
  # Path class just returns +true+. One can either derive a specialized path class or define
  # singleton methods on each path object.
  #
  # == Sample Source Class
  #
  # Following is a simple source class which has stored the paths and their contents in a hash:
  #
  #   require 'stringio'
  #
  #   class MemorySource
  #
  #     CONTENT = {
  #       '/directory/' => nil,
  #       '/directory/file.page' => "This is the content of the file"
  #     }
  #
  #     def paths
  #       CONTENT.collect do |path, content|
  #         Webgen::Path.new(path) { StringIO.new(content.to_s) }
  #       end.to_set
  #     end
  #
  #   end
  #
  # You can use this source class in your website (after placing the code in, for example,
  # <tt>ext/init.rb</tt>) by updating the <tt>sources</tt> configuration option (the following code
  # has to be placed after the definition of the +MemorySource+ class):
  #
  #   WebsiteAccess.website.config['sources'] << ['/', MemorySource]
  #
  module Source

    autoload :Base, 'webgen/source/base'
    autoload :FileSystem, 'webgen/source/filesystem'
    autoload :Stacked, 'webgen/source/stacked'
    autoload :Resource, 'webgen/source/resource'
    autoload :TarArchive, 'webgen/source/tararchive'

  end

end
