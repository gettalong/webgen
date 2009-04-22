# -*- encoding: utf-8 -*-

require 'webgen/cli'
require 'webgen/websitemanager'

module Webgen::CLI

  # The CLI command for creating a webgen website.
  class CreateCommand < CmdParse::Command

    def initialize #:nodoc:
      super('create', false)
      self.description = Utils.format("If the verbosity level is set to verbose, the created files are listed.")
      @bundles = []

      self.short_desc = 'Create a basic webgen website from website bundles'
      self.options = CmdParse::OptionParserWrapper.new do |opts|
        opts.separator "Options:"
        opts.on('-b', '--bundle BUNDLE', String, "A website bundle name/URL or 'none'. Can be used more than once (default: [default, style-andreas07])") do |val|
          if val.downcase == 'none'
            @bundles = nil
          elsif !@bundles.nil?
            @bundles << val
          end
        end
        opts.separator ""
        opts.separator "Arguments:"
        opts.separator opts.summary_indent + "DIR: the directory in which the website should be created"
      end
    end

    def usage # :nodoc:
      "Usage: #{commandparser.program_name} [global options] create [options] DIR"
    end

    def show_help # :nodoc:
      super
      wm = Webgen::WebsiteManager.new(commandparser.directory)

      puts
      puts "Available bundles:"
      puts Utils.headline('Bundles')
      wm.bundles.sort.each {|name, entry| Utils.hash_output(name, entry.instance_eval { @table }) }
    end

    # Create a webgen website in the directory <tt>args[0]</tt>.
    def execute(args)
      if args.length == 0
        raise OptionParser::MissingArgument.new('DIR')
      else
        wm = Webgen::WebsiteManager.new(args[0])
        paths = wm.create_website
        begin
          if @bundles
            @bundles = ['default', 'style-andreas07'] if @bundles.empty?
            @bundles.each {|name| paths += wm.apply_bundle(Utils.match_bundle_name(wm, name)) }
          end
        rescue
          require 'fileutils'
          FileUtils.rm_rf(args[0])
          raise
        end
        if commandparser.verbosity == :verbose
          puts "The following files were created in the directory #{args[0]}:"
          puts paths.sort.join("\n")
        end
      end
    end

  end

end
