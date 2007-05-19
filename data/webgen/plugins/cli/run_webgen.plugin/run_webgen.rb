module Cli

  module Commands

    class RunWebgen < CmdParse::Command

      def initialize
        super( 'run', false )
      end

      def init_plugin
        self.short_desc = @plugin_manager.plugin_infos.get( plugin_name, 'about', 'summary' )
      end

      def execute( args )
        @plugin_manager['Core/FileHandler'].render_site
      end

    end

  end

end
