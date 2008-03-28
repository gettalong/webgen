require 'fileutils'

module Webgen

  module Output

    class FileSystem

      attr_reader :root

      def initialize(root)
        @root = root
      end

      def write(path)
        dest = File.join(@root, path)
        FileUtils.makedirs(File.dirname(dest))
        if path.type == :directory
          FileUtils.makedirs(dest)
        elsif path.type == :file
          path.io do |src|
            File.open(dest, 'wb') {|f| FileUtils.copy_stream(src, f) }
          end
        else
          raise "Unsupported path type '#{path.type}' for #{path}"
        end
      end

    end

  end

end
