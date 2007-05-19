 module Cli

   module Commands

     class CreateWebsite < CmdParse::Command

       def initialize
         super( 'create', false )
         self.short_desc = "Creates the basic directories and files for webgen."
         self.description = Utils.format( "\nIf the global verbosity level is set to 0 or 1, the created files are listed." )
         @template = 'default'
         @style = 'default'
       end

       def init_plugin
         self.options = CmdParse::OptionParserWrapper.new do |opts|
           opts.separator "Options:"
           opts.on( '-t', '--template TEMPLATE', @plugin_manager['Support/WebsiteManager'].templates.keys,
                    'Specify the template which should be used' ) {|@template|}
           opts.on( '-s', '--style STYLE', @plugin_manager['Support/WebsiteManager'].styles['website'].keys,
                    'Specify the style which should be used' ) {|@style|}
           opts.separator ""
           opts.separator "Arguments:"
           opts.separator opts.summary_indent + "DIR: the base directory for the website"
           opts.separator ""
           opts.separator "Available templates and styles:"
           opts.separator ""
           opts.separator Utils.headline( 'Templates' )
           @plugin_manager['Support/WebsiteManager'].templates.sort.each {|name, entry| Utils.info_output( opts, name, entry.infos ) }
           opts.separator Utils.headline( 'Styles' )
           @plugin_manager['Support/WebsiteManager'].styles['website'].sort.each {|name, entry| Utils.info_output( opts, name, entry.infos ) }
         end
       end

       def usage
         "Usage: #{commandparser.program_name} [global options] create [options] DIR"
       end

       def execute( args )
         if args.length == 0
           raise OptionParser::MissingArgument.new( 'DIR' )
         else
           files = @plugin_manager['Support/WebsiteManager'].create_website( args[0], @template )
           files += @plugin_manager['Support/WebsiteManager'].use_style( args[0], 'website', @style )
           if (0..1) === commandparser.verbosity
             puts "The following files were created:"
             puts files.uniq.collect {|f| "- " + f }.join("\n")
           end
         end
       end

     end

   end

end
