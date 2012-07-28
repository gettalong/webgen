# -*- encoding: utf-8 -*-

require 'open-uri'
require 'zlib'
require 'set'

require 'webgen/source'
require 'webgen/path'
webgen_require 'archive/tar/minitar', 'archive-tar-minitar'

module Webgen
  class Source

    # This class is used to read source paths from a (gzipped) tar archive. The archive can be remote
    # (http(s) or ftp) or local.
    #
    # For example, the following are all valid URIs:
    #   http://example.com/directory/file.tgz
    #   /home/test/my.tar.gz
    #   ftp://ftp.example.com/archives/archive.tar
    #
    class TarArchive

      # The URI of the tar archive.
      attr_reader :uri

      # The glob (see File.fnmatch for details) that is used to specify which paths in the archive should
      # be returned by #paths.
      attr_reader :glob

      # Create a new tar archive source for the URI string +uri+.
      def initialize(website, uri, glob = '**/*')
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
              path = '/' + path unless path[0] == ?/
              data = entry.read.to_s
              Path.new(path, 'modified_at' => Time.at(entry.mtime)) {|mode| StringIO.new(data, mode) }
            end.compact.to_set
          end
        end
        @paths
      end

    end

  end
end
