module Cli

  module Commands

    class RunWebgen < CmdParse::Command

      def initialize
        super( 'run', false )
        self.short_desc = "Runs webgen, ie. generates the HTML files."
      end

      def execute( args )
        @plugin_manager.logger.level = param( 'loggerLevel', 'Core/Configuration' )
        log(:info) { "Starting rendering of website <#{param('websiteDir', 'Core/Configuration')}>..." }
        log(:info) { "Using webgen data directory at <#{Webgen.data_dir}>" }
        @plugin_manager['Core/FileHandler'].render_site
        log(:info) { "Rendering of website <#{param('websiteDir', 'Core/Configuration')}> finished" }
      end

    end

  end

end
