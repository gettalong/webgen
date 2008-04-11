require 'fileutils'

module Webgen::Output

  class FileSystem

    include Webgen::WebsiteAccess

    attr_reader :root

    def initialize(root)
      #copied from source/filesystem.rb
      if root =~ /^[a-zA-Z]:|\//
        @root = root
      else
        @root = File.join(website.config['website.dir'], root)
      end
    end

    def exists?(path)
      File.exists?(File.join(@root, path))
    end

    def delete(path)
      dest = File.join(@root, path)
      FileUtils.rm(dest) if File.exists?(dest)
    end

    def write(path, data, type = :file)
      dest = File.join(@root, path)
      FileUtils.makedirs(File.dirname(dest))
      if type == :directory
        FileUtils.makedirs(dest)
      elsif type == :file
        if data.kind_of?(String)
          File.open(dest, 'wb') {|f| f.write(data) }
        else
          File.open(dest, 'wb') {|f| FileUtils.copy_stream(data, f) }
        end
      else
        raise "Unsupported path type '#{type}' for #{path}"
      end
    end

  end

end
