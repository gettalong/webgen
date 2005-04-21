#
#--
#
# $Id$
#
# webgen: template based static website generator
# Copyright (C) 2004 Thomas Leitner
#
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU
# General Public License as published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program; if not,
# write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#++
#

require 'logger'
require 'webgen/plugin'

module Webgen

  class Logger < ::Logger

    def initialize( dev, files, size, level )
      super( dev, files, size )
      self.datetime_format = "%Y-%m-%d %H:%M:%S"
      self.level = level
    end

    def format_message( severity, timestamp, msg, progname )
      "%s %5s -- %s: %s\n" % [timestamp, severity, progname, msg ]
    end

    def warn( progname = nil, &block )
      super
      self.debug { "Call stack for last warning: #{caller[3..-1].join("\n")}" }
    end

    def error( progname = nil, &block )
      super
      self.debug { "Call stack for last error: #{caller[3..-1].join("\n")}" }
    end

  end

end

class Object

  @@logger = Webgen::Logger.new( STDERR, 0, 0, Logger::ERROR )

  def self.set_logger( logger )
    @@logger = logger
  end

  def logger
    @@logger
  end

end

class Module

  def self.logger
    Object::LOGGER
  end

end

module Webgen

  class Logging < Plugin

    summary "Plugin for configuring the logger"

    add_param 'maxLogFiles', 10, 'The maximum number of log files'
    add_param 'maxLogSize', 1024*1024, 'The maximum size of the log files'
    add_param 'verbosityLevel', 2, 'The level of verbosity for the output of logging messages (0=DEBUG, 1=INFO, 2=WARNING 3=ERROR).',
       lambda {|p,o,n| logger.level = n }
    add_param 'logToFile', false, 'Specifies if the log messages should be put to the logfile',
       (lambda do |p, o, n|
          dev = STDERR
          if n
            Dir.mkdir( 'log' ) unless File.exists?( 'log' )
            dev = 'log/webgen.log'
          end
          Object.set_logger( Webgen::Logger.new( dev, get_param( 'maxLogFiles' ), get_param( 'maxLogSize' ), get_param( 'verbosityLevel') ) )
        end)

  end

  # Initialize single logging instance
  Plugin.config[Logging].obj = Logging.new

end
