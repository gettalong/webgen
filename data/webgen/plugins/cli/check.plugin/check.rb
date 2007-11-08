 module Cli

   module Commands

     class Check < CmdParse::Command

       def initialize
         super( 'check', false )
         @check_config = false
         @check_plugins = false
       end

       def init_plugin
         self.short_desc = @plugin_manager.plugin_infos.get( plugin_name, 'about', 'summary' )
         self.description = 'If no specific check is specified, all checks are executed.'
         self.options = CmdParse::OptionParserWrapper.new do |opts|
           opts.separator "Options:"
           opts.on( '-c', '--config', 'Check the configuration file' ) {|@check_config|}
           opts.on( '-p', '--plugins', 'Check the availability of all plugins' ) {|@check_plugins|}
         end
       end

       def execute( args )
         check_config if @check_config
         check_plugins if @check_plugins

         if !@check_config && !@check_plugins
           check_config
           check_plugins
         end
       end

       def check_config
         if !File.exists?( Webgen::FileConfigurator.config_file( commandparser.directory ) )
           puts Utils.section( "No configuration file found!", 50, 0, :bold )
           return
         end
         begin
           print Utils.section( "Checking configuration file syntax...", 50, 0, :bold )
           config_file = Webgen::FileConfigurator.for_website( commandparser.directory )
           puts Utils.green( 'OK' )

           puts Utils.section( "Checking parameters...", 0, 0, :bold )
           config_file.config.each do |plugin_name, params|
             params.each do |param_name, value|
               print Utils.section( "#{plugin_name}:#{param_name}", 50, 2, :reset )
               if !@plugin_manager.plugin_infos.has_key?( plugin_name )
                 puts Utils.lred( 'NOT OK' ) + ': no such plugin'
               elsif !@plugin_manager.plugin_infos.get( plugin_name, 'params', param_name )
                 puts Utils.lred( 'NOT OK' ) + ': no such parameter'
               else
                 puts Utils.green( 'OK' )
               end
             end
           end
         rescue Webgen::ConfigurationFileInvalid => e
           puts Utils.lred( 'NOT OK' ) + ': ' + e.message
         end
       end

       def check_plugins
         print Utils.section( "Checking plugins...", 50, 0, :bold )
         one_unloadable_found = false
         @plugin_manager.plugin_infos.keys.each do |plugin_name|
           begin
             @plugin_manager.init_plugins( [plugin_name] )
           rescue
             puts if !one_unloadable_found
             puts Utils.section( plugin_name, 50, 2, :reset ) + Utils.lred( 'NOT OK: ' ) + $!.message
             one_unloadable_found = true
           end
         end
         puts Utils.green( 'OK' ) if !one_unloadable_found
       end

     end

   end

end
