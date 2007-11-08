 module Cli

   module Commands

     class ApplyStyle < CmdParse::Command

       def initialize
         super( 'apply_style', false )
         self.description = "\n" + Utils.format( "If the global verbosity level is set to 0 or 1, the created files are listed." ).join("\n")
       end

       def init_plugin
         self.short_desc = @plugin_manager.plugin_infos.get( plugin_name, 'about', 'summary' )
         self.options = CmdParse::OptionParserWrapper.new do |opts|
           opts.separator "Available styles types and styles:"
           opts.separator ""
           @plugin_manager['Support/WebsiteManager'].styles.each do |type, styles|
             opts.separator Utils.headline( type )
             styles.sort.each {|name, entry| Utils.info_output( opts, name, entry.infos ) }
           end
         end
       end

       def usage
         "Usage: #{commandparser.program_name} [global options] apply_style STYLE_TYPE STYLE_NAME"
       end

       def execute( args )
         if args.length != 2
           puts 'You have to specify exactly one style type and one style name to use!'
           return
         end
         if !(@plugin_manager['Support/WebsiteManager'].styles.has_key?( args[0] ) &&
              @plugin_manager['Support/WebsiteManager'].styles[args[0]].has_key?( args[1] )
              )
           puts 'The specified style type/style name combination could not be found!'
           return
         end
         files = @plugin_manager['Support/WebsiteManager'].use_style( commandparser.website.directory, args[0], args[1] )
         if (0..1) === commandparser.verbosity
           puts "The following files were created/updated:"
           puts files.uniq.collect {|f| "- " + f }.join("\n")
         end
       end

     end

   end

end
