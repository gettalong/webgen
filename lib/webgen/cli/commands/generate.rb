# -*- encoding: utf-8 -*-

require 'webgen/cli/utils'

module Webgen
  module CLI

    # The CLI command for generating a webgen website.
    class GenerateCommand < CmdParse::Command

      def initialize # :nodoc:
        super('generate', false, false, false)
        self.short_desc = 'Generate the webgen website'
        self.description = Webgen::CLI::Utils.format_command_desc(<<EOF)
This command is executed by default when no other command was specified.
EOF
        self.options = CmdParse::OptionParserWrapper.new do |opts|
          opts.separator "Options:"
          opts.on('-a', '--auto [SEC]', Integer,
                  *Utils.format_option_desc("Auto-generate the website every SEC seconds (5=default, 0=off)")) do |val|
            @auto_generate_secs = val || 5
          end
        end
        @auto_generate_secs = 0
      end

      def execute(args) # :nodoc:
        if @auto_generate_secs <= 0
          commandparser.website.execute_task(:generate_website)
        else
          auto_generate
        end
      end

      def auto_generate #:nodoc:
        puts 'Starting auto-generate mode'

        time = Time.now
        abort = false
        old_paths = []
        dirs = "{" << commandparser.website.config['sources'].map do |mp, type, *args|
          type == :file_system ? File.join(commandparser.website.directory, args[0], args[1] || '**/*') : nil
        end.compact.join(',') << "}"

        Signal.trap('INT') {abort = true}

        while !abort
          paths = Dir[dirs].sort
          if old_paths != paths || paths.any? {|p| File.file?(p) && File.mtime(p) > time}
            begin
              commandparser.website(true).execute_task(:generate_website)
            rescue Webgen::Error => e
              puts e.message
            end
          end
          time = Time.now
          old_paths = paths
          sleep @auto_generate_secs
        end
      end
      private :auto_generate

    end

  end
end
