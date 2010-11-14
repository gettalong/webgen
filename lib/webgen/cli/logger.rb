# -*- encoding: utf-8 -*-

require 'logger'
require 'webgen/cli/utils'

module Webgen

  module CLI

    # The logger class used by the command line interface.
    class Logger < ::Logger

      # Create a new Logger object for the command line interface.
      def initialize(outdev = $stdout)
        super(outdev)
        outdev.sync = true if outdev.respond_to?(:sync=)
        self.formatter = Proc.new do |severity, timestamp, progname, msg|
          msg = msg.dup
          msg.gsub!(/<.*?>/) {|m| Utils.bold(m)}
          case severity
          when 'INFO'
            if msg =~ /^\[.*?\] /
              msg.insert(0, '  ')
            else
              msg.chomp!
              msg << "\n"
            end
            msg.sub!(/^\s*\[(?:create|update)\]/) {|m| Utils.bold(Utils.green(m))}
            msg
          when 'WARN'
            "%s%9s%s %s\n" % [Utils.bold + Utils.yellow, severity, Utils.reset, msg]
          when 'ERROR', 'FATAL'
            "%s%9s%s %s\n" % [Utils.bold + Utils.red, severity, Utils.reset, msg]
          when 'DEBUG'
            "%9s%s %s\n" % [severity, progname ? " (#{progname})" : '', msg]
          else
            raise ArgumentError, 'Unsupported logger severity level'
          end
        end
        self.level = ::Logger::INFO
      end

    end

  end

end
