# -*- encoding: utf-8 -*-

require 'webgen/cli'
require 'webgen/websitemanager'

module Webgen::CLI

  # The CLI command for applying a bundle to a webgen website.
  class ApplyCommand < CmdParse::Command

    def initialize #:nodoc:
      super('apply', false)
      @force = false

      self.short_desc = 'Apply a website bundle to an existing webgen website'
      self.options = CmdParse::OptionParserWrapper.new do |opts|
        opts.separator "Options:"
        opts.on('-f', '--[no-]force', 'Specifies whether files should be overwritten (default: no)') do |val|
          @force = val
        end
        opts.separator ""
        opts.separator "Arguments:"
        opts.separator opts.summary_indent + "BUNDLE_NAME: The name of a bundle shipped with webgen. The name is "
        opts.separator opts.summary_indent + "    matched against all possible bundle names and if there is only "
        opts.separator opts.summary_indent + "    match the bundle is applied."
        opts.separator opts.summary_indent + "BUNDLE_URL:  The URL of a bundle (needs to be a tar archive"
      end
    end

    def usage # :nodoc:
      "Usage: #{commandparser.program_name} [global options] apply [options] (BUNDLE_NAME|BUNDLE_URL)"
    end

    def show_help # :nodoc:
      super
      wm = Webgen::WebsiteManager.new(commandparser.directory)

      puts
      puts "Available bundles:"
      puts Utils.headline('Bundles')
      wm.bundles.sort.each {|name, entry| Utils.hash_output(name, entry.instance_eval { @table }) }
    end

    # Apply the style specified in <tt>args[0]</tt> to the webgen website.
    def execute(args)
      wm = Webgen::WebsiteManager.new(commandparser.directory)
      if !File.directory?(wm.website.directory)
        raise "You need to specify a valid webgen website directory!"
      elsif args.length == 0
        raise OptionParser::MissingArgument.new('STYLE')
      else
        name = Utils.match_bundle_name(wm, args[0])
        puts "The following files in the website directory will be created or overwritten:"
        puts wm.bundles[name].paths.sort.join("\n")
        continue = @force
        if !continue
          print "Procede? (yes/no): "
          continue = ($stdin.readline =~ /y(es)?/)
        end
        wm.apply_bundle(name) if continue
      end
    end

  end

end
