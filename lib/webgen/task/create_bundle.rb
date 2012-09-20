# -*- encoding: utf-8 -*-

require 'webgen/task'
require 'webgen/utils'
require 'fileutils'

module Webgen
  class Task

    # Creates an extension bundle.
    #
    # An extension bundle is a collection of webgen extensions. This task can either create a local
    # bundle (in the +ext+ directory of the current website) or a bundle which can be distributed
    # via Rubygems.
    #
    module CreateBundle

      TEMPLATE_DIR = 'bundle_template_files'

      # Create an extension bundle with the given name and of the given type (either :local or :gem).
      #
      # If the type is :gem, the directory in which the bundle should be created can optionally be
      # specified.
      #
      # Returns +true+ if the bundle has been created.
      def self.call(website, name, type, directory = name)
        dir = if type == :gem
                create_distribution_bundle(website, directory, name)
              else
                create_local_bundle(website, name)
              end
        website.logger.info { "Bundle '#{name}' of type '#{type}' created at <#{dir}>" }

        true
      end

      def self.create_distribution_bundle(website, directory, bundle_name) #:nodoc:
        bundle_dir = File.join(directory, 'lib', 'webgen', 'bundle', bundle_name)

        create_directory(directory)
        create_directory(bundle_dir)
        create_file(File.join(directory, 'Rakefile'), 'Rakefile.erb', bundle_name)
        create_file(File.join(directory, 'README.md'), 'README.md.erb', bundle_name)
        create_file(File.join(bundle_dir, 'info.yaml'), 'info.yaml.erb', bundle_name)
        create_file(File.join(bundle_dir, 'init.rb'), 'init.rb.erb', bundle_name)
        directory
      end

      def self.create_local_bundle(website, bundle_name) #:nodoc:
        bundle_dir =  File.join(website.directory, 'ext', bundle_name)

        create_directory(bundle_dir)
        create_file(File.join(bundle_dir, 'info.yaml'), 'info.yaml.erb', bundle_name)
        create_file(File.join(bundle_dir, 'init.rb'), 'init.rb.erb', bundle_name)
        bundle_dir
      end

      def self.create_directory(dir) #:nodoc:
        raise "The directory '#{dir}' does already exist" if File.exist?(dir)
        FileUtils.mkdir_p(dir)
      end

      def self.create_file(dest, source, bundle_name) #:nodoc:
        File.open(dest, 'w+') do |f|
          erb = ERB.new(File.read(File.join(Webgen::Utils.data_dir, TEMPLATE_DIR, source)))
          f.write(erb.result(binding))
        end
      end

    end

  end
end
