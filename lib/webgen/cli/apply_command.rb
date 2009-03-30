# -*- encoding: utf-8 -*-

require 'webgen/cli'
require 'webgen/websitemanager'

module Webgen::CLI

  # The CLI command for applying a style to a webgen website.
  class ApplyCommand < CmdParse::Command

    def initialize #:nodoc:
      super('apply', false)
      @force = false

      self.short_desc = 'Apply a website style to an existing webgen website'
      self.options = CmdParse::OptionParserWrapper.new do |opts|
        opts.separator "Options:"
        opts.on('-f', '--[no-]force', 'Specifies whether files should be overwritten (default: no)') do |val|
          @force = val
        end
        opts.separator ""
        opts.separator "Arguments:"
        opts.separator opts.summary_indent + "STYLE: the style the should be applied to the website"
      end
    end

    def usage # :nodoc:
      "Usage: #{commandparser.program_name} [global options] apply [options] STYLE"
    end

    def show_help # :nodoc:
      super
      wm = Webgen::WebsiteManager.new(commandparser.directory)

      puts
      puts "Available styles:"
      puts Utils.headline('Styles')
      wm.styles.sort.each {|name, entry| Utils.hash_output(name, entry.instance_eval { @table }) }
    end

    # Apply the style specified in <tt>args[0]</tt> to the webgen website.
    def execute(args)
      wm = Webgen::WebsiteManager.new(commandparser.directory)
      if !File.directory?(commandparser.directory)
        puts "You need to specify a valid webgen website directory!"
      elsif args.length == 0
        raise OptionParser::MissingArgument.new('STYLE')
      elsif !wm.styles.has_key?(args[0])
        raise OptionParser::InvalidArgument.new("#{args[0]} is not a valid style")
      else
        puts "The following files in the website directory will be created or overwritten:"
        puts wm.styles[args[0]].paths.to_a.sort.join("\n")
        continue = @force
        if !continue
          print "Procede? (yes/no): "
          continue = ($stdin.readline =~ /y(es)?/)
        end
        wm.apply_style(args[0]) if continue
      end
    end

  end

end
