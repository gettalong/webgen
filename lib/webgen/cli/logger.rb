# -*- encoding: utf-8 -*-

require 'webgen/logger'
require 'webgen/cli/utils'

module Webgen

  module CLI

    # The logger class used by the command line interface.
    class Logger < Webgen::Logger

      attr_accessor :prefix

      # Create a new Logger object for the command line interface.
      def initialize(outdev = $stdout)
        super(outdev)
        @prefix = ''
        outdev.sync = true if outdev.respond_to?(:sync=)
        self.formatter = Proc.new do |severity, timestamp, progname, msg|
          msg = msg.dup
          msg.gsub!(/<.*?>/) {|m| Utils.bold(m)}
          msg.gsub!(/\n/, "\n      ")
          case severity
          when 'INFO'
            msg.sub!(/^\s*\[(?:create|update)\]/) {|m| Utils.bold(Utils.green(m))}
            "%s%-5s %s\n" % [@prefix, severity, msg]
          when 'WARN'
            "%s%s%-5s%s %s\n" % [@prefix, Utils.bold + Utils.yellow, severity, Utils.reset, msg]
          when 'ERROR', 'FATAL'
            "%s%s%-5s%s %s\n" % [@prefix, Utils.bold + Utils.red, severity, Utils.reset, msg]
          when 'DEBUG'
            "%s%-5s%s %s\n" % [@prefix, severity, progname ? " (#{progname})" : '', msg]
          else
            raise ArgumentError, 'Unsupported logger severity level'
          end
        end
        self.level = ::Logger::INFO
      end

    end

  end

end
