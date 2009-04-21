# -*- encoding: utf-8 -*-

require 'webgen/cli'
require 'webgen/websitemanager'

module Webgen::CLI

  # The CLI command for creating a webgen website.
  class CreateCommand < CmdParse::Command

    def initialize #:nodoc:
      super('create', false)
      self.description = Utils.format("If the verbosity level is set to verbose, the created files are listed.")
      @template = 'default'
      @style = 'andreas07'

      self.short_desc = 'Create a basic webgen website with selectable template/style'
      self.options = CmdParse::OptionParserWrapper.new do |opts|
        opts.separator "Options:"
        opts.on('-t', '--template TEMPLATE', String, "A website template or 'none' (default: #{@template})") do |val|
          @template = (val.lowercase == 'none' ? nil : val)
        end
        opts.on('-s', '--style STYLE', String, "A website style or 'none' (default: #{@style})") do |val|
          @style = (val.lowercase == 'none' ? nil : val)
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
      puts "Available templates and styles:"
      puts Utils.headline('Templates')
      wm.templates.sort.each {|name, entry| Utils.hash_output(name, entry.instance_eval { @table }) }
      puts Utils.headline('Styles')
      wm.styles.select {|k,v| k =~ /^website-|[^-]+/ }.sort.each {|name, entry| Utils.hash_output(name, entry.instance_eval { @table }) }
    end

    # Create a webgen website in the directory <tt>args[0]</tt>.
    def execute(args)
      if args.length == 0
        raise OptionParser::MissingArgument.new('DIR')
      else
        wm = Webgen::WebsiteManager.new(args[0])
        paths = wm.create_website
        paths += wm.apply_template(@template) if @template
        paths += wm.apply_style(@style) if @style
        if commandparser.verbosity == :verbose
          puts "The following files were created in the directory #{args[0]}:"
          puts paths.sort.collect {|f| "- " + f }.join("\n")
        end
      end
    end

  end

end
