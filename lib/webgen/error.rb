# -*- encoding: utf-8 -*-

module Webgen

  # Custom webgen error.
  class Error < StandardError

    # The name of the class where the error happened.
    attr_reader :class_name

    # This is either the source path or the node alcn which is responsible for the error.
    attr_accessor :alcn


    # Create a new Error using the provided values.
    #
    # If +msg_or_error+ is a String, it is treated as the error message. If it is an exception, the
    # exception is wrapped.
    def initialize(msg_or_error, class_name = nil, alcn = nil)
      if msg_or_error.kind_of?(String)
        super(msg_or_error)
      else
        super(msg_or_error.message)
        set_backtrace(msg_or_error.backtrace)
      end
      @class_name, @alcn = class_name, alcn
    end

    # Return a beefed-up error message including the +class_name+ and +alcn+.
    def pretty_message
      msg = 'Error while working'
      msg += (@alcn ? " on <#{@alcn}>" : '')
      msg += " with #{@class_name}" if @class_name
      msg + ":\n    " + self.message
    end

  end

  # This error is raised when an error condition occurs during the creation of a node.
  class NodeCreationError < Error

    # See Error#pretty_message.
    def pretty_message
      msg = 'Error while creating a node'
      msg += (@alcn ? " from <#{@alcn}>" : '')
      msg += " with #{@class_name}" if @class_name
      msg + ":\n    " + self.message
    end

  end


  # This error is raised when an error condition occurs during rendering of a node.
  class RenderError < Error

    # The alcn of the file where the error happened. This can be different from #alcn (e.g. a page
    # file is rendered but the error happens in a used template).
    attr_accessor :error_alcn

    # The line number in the +error_alcn+ where the errror happened.
    attr_accessor :line

    # Create a new RenderError using the provided values.
    #
    # If +msg_or_error+ is a String, it is treated as the error message. If it is an exception, the
    # exception is wrapped.
    def initialize(msg_or_error, class_name = nil, alcn = nil, error_alcn = nil, line = nil)
      super(msg_or_error, class_name, alcn)
      @error_alcn, @line = error_alcn, line
    end

    # See Error#pretty_message.
    def pretty_message
      msg = 'Error '
      if @error_alcn
        msg += "in <#{@error_alcn}"
        msg += ":~#{@line}" if @line
        msg += "> "
      end
      msg += 'while rendering '
      msg += (@alcn ? "<#{@alcn}>" : 'the website')
      msg += " with #{@class_name}" if @class_name
      msg + ":\n    " + self.message
    end

  end

end
