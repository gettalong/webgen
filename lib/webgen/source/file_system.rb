# -*- encoding: utf-8 -*-

require 'pathname'
require 'set'
require 'webgen/source'
require 'webgen/path'

module Webgen
  class Source

    # This class is used to read source paths from a directory in the file system.
    class FileSystem

      # The root path from which paths are read.
      attr_reader :root

      # The glob (see Dir.glob for details) that is used to specify which paths under the root path
      # should be returned by #paths.
      attr_reader :glob

      # Create a new file system source for the root path +root+ using the provided +glob+. If
      # +root+ is not an absolute path, the website directory will be prepended.
      def initialize(website, root, glob = '{*,**/*}')
        @root = File.absolute_path(root, website.directory)
        @glob = glob
      end

      # Return all paths under the root path which match the glob.
      def paths
        @paths ||= Dir.glob(File.join(@root, @glob), File::FNM_DOTMATCH|File::FNM_CASEFOLD).collect do |f|
          next unless File.exist?(f) && f !~ /\/\.\.$/ # handle invalid links
          temp = Pathname.new(f.sub(/^#{Regexp.escape(@root)}\/?/, '/')).cleanpath.to_s
          temp += '/' if File.directory?(f) && temp[-1] != ?/
          Path.new(temp, 'modified_at' => File.mtime(f)) {|mode| File.open(f, mode)}
        end.compact.to_set
      end

    end

  end
end
