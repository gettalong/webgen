# -*- encoding: utf-8 -*-

require 'webgen/destination'
require 'fileutils'

module Webgen
  class Destination

    # This class uses the file systems as output device. On initialization a root path is set and
    # all other operations are taken relative to this root path.
    class FileSystem

      # The root path, ie. the path to which the root node gets rendered.
      attr_reader :root

      # Create a new FileSystem object with the given +root+ path. If +root+ is not absolute, it is
      # taken relative to the website directory.
      def initialize(website, root)
        @root = File.absolute_path(root, website.directory)
      end

      # Return +true+ if the given path exists.
      def exists?(path)
        File.exist?(File.join(@root, path))
      end

      # Delete the given +path+
      def delete(path)
        dest = File.join(@root, path)
        if File.directory?(dest)
          FileUtils.rm_rf(dest)
        else
          FileUtils.rm(dest)
        end
      end

      # Write the +data+ to the given +path+.
      def write(path, data)
        dest = File.join(@root, path)
        parent_dir = File.dirname(dest)
        FileUtils.makedirs(parent_dir) unless File.directory?(parent_dir)
        if path[-1] == ?/
          FileUtils.makedirs(dest)
        else
          if data.kind_of?(String)
            File.open(dest, 'wb') {|f| f.write(data) }
          else
            data.io('rb') do |source|
              File.open(dest, 'wb') {|f| FileUtils.copy_stream(source, f) }
            end
          end
        end
      end

      # Return the content of the given +path+ which is opened in +mode+.
      def read(path, mode = 'rb')
        File.open(File.join(@root, path), mode) {|f| f.read}
      end

    end

  end
end
