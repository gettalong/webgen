# -*- encoding: utf-8 -*-

require 'pathname'
require 'webgen/websiteaccess'
require 'webgen/path'

module Webgen

  # This class is used to read source paths from a directory in the file system.
  class Source::FileSystem

    # A special Webgen::Path class for handling with file system paths.
    class Path < Webgen::Path

      # Create a new object with absolute path +path+ for the file system path +fs_path+.
      def initialize(path, fs_path)
        super(path) { File.open(fs_path, 'rb') }
        @fs_path = fs_path
        WebsiteAccess.website.cache[[:fs_path, @fs_path]] = File.mtime(@fs_path)
        @meta_info['modified_at'] = File.mtime(@fs_path)
      end

      # Return +true+ if the file system path used by the object has been modified.
      def changed?
        data = WebsiteAccess.website.cache[[:fs_path, @fs_path]]
        File.mtime(@fs_path) > data
      end

    end

    # The root path from which paths read.
    attr_reader :root

    # The glob (see Dir.glob for details) that is used to specify which paths under the root path
    # should be returned by #paths.
    attr_reader :glob

    # Create a new file system source for the root path +root+ using the provided +glob+.
    def initialize(root, glob = '**/*')
      if root =~ /^([a-zA-Z]:|\/)/
        @root = root
      else
        @root = File.join(WebsiteAccess.website.directory, root)
      end
      @glob = glob
    end

    # Return all paths under #root which match #glob.
    def paths
      @paths ||= Dir.glob(File.join(@root, @glob), File::FNM_DOTMATCH|File::FNM_CASEFOLD).to_set.collect do |f|
        next unless File.exists?(f) # handle invalid links
        temp = Pathname.new(f.sub(/^#{Regexp.escape(@root)}\/?/, '/')).cleanpath.to_s
        temp += '/' if File.directory?(f) && temp[-1] != ?/
        path = Path.new(temp, f)
        path
      end.compact
    end

  end

end
