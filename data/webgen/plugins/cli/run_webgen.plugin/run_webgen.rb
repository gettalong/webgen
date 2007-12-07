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
        @plugin_manager['Core/FileHandler'].render_website
        # 2nd run, to ensure fragments are handled correctly, TODO: only when something has changed
        commandparser.create_website.plugin_manager['Core/FileHandler'].render_website
      end

    end

  end

end
