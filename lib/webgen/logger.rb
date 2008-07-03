require 'stringio'
require 'logger'

module Webgen

  # The class used by a Website to do the logging and the normal output.
  class Logger

    # Specifies whether log output should be synchronous with normal output.
    attr_reader :sync

    # Normal output verbosity (:normal, :verbose, :quiet).
    attr_accessor :verbosity

    # Create a new Logger object which uses +outdev+ as output device. If +sync+ is set to +true+,
    # log messages are interspersed with normal output.
    def initialize(outdev=$stdout, sync=false)
      @sync = sync
      @outdev = outdev
      @logger = (@sync ? ::Logger.new(@outdev) : ::Logger.new(@logio = StringIO.new))
      @logger.formatter = Proc.new do |severity, timestamp, progname, msg|
        if self.level == ::Logger::DEBUG
          "%5s -- %s: %s\n" % [severity, progname, msg ]
        else
          "%5s -- %s\n" % [severity, msg]
        end
      end
      self.level = ::Logger::WARN
      self.verbosity = :normal
    end

    # Returns the output of the logger when #sync is +false+. Otherwise an empty string is returned.
    def log_output
      @sync ? '' : @logio.string
    end

    # The severity threshold level.
    def level
      @logger.level
    end

    # Set the severity threshold to +value+ which can be one of the stdlib Logger severity levels.
    def level=(value)
      @logger.level = value
    end

    # Log a message of +sev_level+ from +source+. The mandatory block has to return the message.
    def log(sev_level, source='', &block)
      if sev_level == :stdout
        @outdev.write(block.call + "\n") if @verbosity == :normal || @verbosity == :verbose
      elsif sev_level == :verbose
        @outdev.write(block.call + "\n") if @verbosity == :verbose
      else
        @logger.send(sev_level, source, &block)
      end
    end

    # Utiltity method for logging an error message.
    def error(source='', &block); log(:error, source, &block); end

    # Utiltity method for logging a warning message.
    def warn(source='', &block); log(:warn, source, &block); end

    # Utiltity method for logging an informational message.
    def info(source='', &block); log(:info, source, &block); end

    # Utiltity method for logging a debug message.
    def debug(source='', &block); log(:debug, source, &block); end

    # Utiltity method for writing a normal output message.
    def stdout(source='', &block); log(:stdout, source, &block); end

    # Utiltity method for writing a verbose output message.
    def verbose(source='', &block); log(:verbose, source, &block); end

  end

end
