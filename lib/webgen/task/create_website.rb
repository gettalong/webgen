# -*- encoding: utf-8 -*-

require 'webgen/website'
require 'webgen/task'
require 'webgen/error'
require 'tmpdir'

module Webgen
  class Task

    #
    # == About
    #
    # Creates the website.
    #
    # This task assumes that the website directory does not exist and populates it from a specified
    # template. webgen extensions can provide additional website templates, see below.
    #
    # For each created file a verbose log message is recorded in the format used when webgen
    # generates a website (because, actually, webgen's website generating facilities are used to
    # create the website structure).
    #
    # == Creating a website template
    #
    # A website template is just a directory holding all the files necessary for a webgen website
    # and therefore looks very similar to an actual webgen website directory. However, the template
    # is not just copied but processed ('generated') by webgen itself.
    #
    # What this means is:
    #
    # * A Webgen::Website object is created for a temporary directory.
    # * The 'destination' configuration option is set to the to-be-created website directory (ie. to
    #   Website#directory of the current website).
    # * The 'sources' configuration option is set to use the website template directory.
    # * All path handlers are deactivated except Webgen::PathHandler::Copy and the latter is used
    #   for processing all source paths.
    #
    # Thus one can use Erb or any other supported content processor to customize the generated
    # files!
    #
    # Once a website template has been created, it needs to be registered with a template name, like
    # this:
    #
    #   website.ext.task.data(:create_website)[:templates][TEMPLATE_NAME] = ABSOLUTE_DIR_PATH
    #
    module CreateWebsite

      # This error is raised when there is a problem creating the website.
      class Error < Webgen::Error; end

      # Create the website from the given template.
      #
      # This actually uses webgen's file copying/generating facilities to populate the website
      # directory. Kind of bootstrapping really.
      #
      # Returns +true+ if the website has been created.
      def self.call(website, template = nil)
        if File.exists?(website.directory)
          raise Error.new("Directory <#{website.directory}> does already exist!")
        end
        if template && !website.ext.task.data(:create_website)[:templates].has_key?(template)
          raise Error.new("Unknown template '#{template}' specified!")
        end

        begin
          Dir.mktmpdir do |tmpdir|
            ws = Webgen::Website.new(tmpdir) do |ws|
              ws.config['sources'] = [['/', :file_system, File.join(Webgen::Utils.data_dir, 'basic_website_template')]]
              if template
                ws.config['sources'].unshift(['/', :file_system, website.ext.task.data(:create_website)[:templates][template]])
              end
              ws.config['destination'] = [:file_system, File.expand_path(website.directory)]
              ws.ext.path_handler.registered_extensions.each do |name, data|
                data.patterns = []
              end
              ws.ext.path_handler.registered_extensions[:copy].patterns = ['**/*', '**/']
              ws.logger.level = ::Logger::INFO
              ws.logger.formatter = Proc.new do |severity, timestamp, progname, msg|
                website.logger.vinfo(msg) if msg =~ /\[create\]/
              end
            end
            ws.execute_task(:generate_website)
          end
        rescue Webgen::Error => e
          raise Error.new("Could not create website from template: #{e.message}")
        end

        true
      end

    end

  end
end
