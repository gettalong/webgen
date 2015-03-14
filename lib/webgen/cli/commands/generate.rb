# -*- encoding: utf-8 -*-

require 'webgen/cli/utils'

module Webgen
  module CLI

    # The CLI command for generating a webgen website.
    class GenerateCommand < CmdParse::Command

      def initialize # :nodoc:
        super('generate', takes_commands: false)
        short_desc('Generate the webgen website')
        long_desc("This command is executed by default when no other command was specified.")
        options.on('-a', '--auto [SEC]', Integer, "Auto-generate the website every SEC seconds (5=default, 0=off)") do |val|
          @auto_generate_secs = val || 5
        end
        @auto_generate_secs = 0
      end

      def execute # :nodoc:
        if @auto_generate_secs <= 0
          command_parser.website.execute_task(:generate_website)
        else
          auto_generate
        end
      end

      def auto_generate #:nodoc:
        puts 'Starting auto-generate mode'

        time = Time.now
        abort = false
        old_paths = []
        dirs = "{" << command_parser.website.config['sources'].map do |mp, type, *args|
          type == :file_system ? File.join(command_parser.website.directory, args[0], args[1] || '**/*') : nil
        end.compact.join(',') << "}"

        Signal.trap('INT') {abort = true}

        while !abort
          paths = Dir[dirs].sort
          if old_paths != paths || paths.any? {|p| File.file?(p) && File.mtime(p) > time}
            begin
              command_parser.website(true).execute_task(:generate_website)
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
