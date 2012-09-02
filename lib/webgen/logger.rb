# -*- encoding: utf-8 -*-

require 'logger'

module Webgen

  # This custom logger class needs to be used (either directly or via a sub-class) for the
  # Webgen::Website logging object.
  #
  # It provides the following, additional functionality over the stdlib ::Logger class:
  #
  # * If a logging message is an Array and #verbose is +false+, only the first item of the array is
  #   output. If #verbose is +true+, the the items of the array are joined using a line break and
  #   output.
  #
  # * You can add verbose info messages using the #vinfo method.
  #
  class Logger < ::Logger

    # Whether verbose log message should be output. Either +true+ or +false.
    attr_accessor :verbose

    def initialize(*args, &block) #:nodoc:
      super
      @verbose = false
    end

    def format_message(severity, datetime, progname, msg) #:nodoc:
      first, *rest = *msg
      msg = (@verbose ? [first, *rest].join("\n") : first)
      super(severity, datetime, progname, msg)
    end

    # Log a verbose info message.
    def vinfo(progname = nil, &block)
      add(::Logger::INFO, nil, progname, &block) if @verbose
    end

  end

end
