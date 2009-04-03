# -*- encoding: utf-8 -*-

require 'pathname'
require 'webgen/websiteaccess'
require 'webgen/path'
require 'open-uri'
require 'zlib'
require 'archive/tar/minitar'

module Webgen

  # This class is used to read source paths from a (gzipped) tar archive. The archive can be remote
  # (http(s) or ftp) or local.
  #
  # For example, the following are all valid URIs:
  #   http://example.com/directory/file.tgz
  #   /home/test/my.tar.gz
  #   ftp://ftp.example.com/archives/archive.tar
  #
  class Source::TarArchive

    # A special Webgen::Path class for handling paths from a tar archive.
    class Path < Webgen::Path

      # Create a new tar archive path object for the entry +entry+.
      def initialize(path, data, mtime, uri)
        super(path) { StringIO.new(data.to_s) }
        @uri = uri
        @mtime = mtime
        WebsiteAccess.website.cache[[:tararchive_path, @uri, path]] = @mtime if WebsiteAccess.website
        @meta_info['modified_at'] = @mtime
      end

      # Return +true+ if the tar archive path used by the object has been modified.
      def changed?
        !WebsiteAccess.website || @mtime > WebsiteAccess.website.cache[[:tararchive_path, @uri, path]]
      end

    end

    # The URI of the tar archive.
    attr_reader :uri

    # The glob (see File.fnmatch for details) that is used to specify which paths in the archive should
    # be returned by #paths.
    attr_reader :glob

    # Create a new tar archive source for the URI string +uri+.
    def initialize(uri, glob = '**/*')
      @uri = uri
      @glob = glob
    end

    # Return all paths in the tar archive available at #uri.
    def paths
      if !defined?(@paths)
        stream = open(@uri)
        stream = Zlib::GzipReader.new(stream) if @uri =~ /(\.tar\.gz|\.tgz)$/
        Archive::Tar::Minitar::Input.open(stream) do |input|
          @paths = input.collect do |entry|
            path = entry.full_name
            next unless File.fnmatch(@glob, path, File::FNM_DOTMATCH|File::FNM_CASEFOLD|File::FNM_PATHNAME)
            path += '/' if entry.directory? && path[-1] != ?/
            Path.new(path, entry.read, Time.at(entry.mtime), @uri)
          end.compact.to_set
        end
      end
      @paths
    end

  end

end
