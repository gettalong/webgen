# -*- encoding: utf-8 -*-

module Webgen

  # Custom webgen error.
  class Error < StandardError

    # The name of the class where the error happened.
    attr_reader :class_name

    # This is either the source path or the node alcn which is responsible for the error.
    attr_accessor :alcn

    # The plain error message.
    attr_reader :plain_message

    # Create a new Error using the provided values.
    #
    # If +msg_or_error+ is a String, it is treated as the error message. If it is an exception, the
    # exception is wrapped.
    def initialize(msg_or_error, class_name = nil, alcn = nil)
      if msg_or_error.kind_of?(String)
        super(msg_or_error)
        @plain_message = msg_or_error
      else
        super(msg_or_error.message)
        set_backtrace(msg_or_error.backtrace)
        @plain_message = msg_or_error.message
      end
      @class_name, @alcn = class_name, (alcn.kind_of?(Node) ? alcn.to_s : alcn)
    end

    def message # :nodoc:
      msg = 'Error while working'
      msg += (@alcn ? " on <#{@alcn}>" : '')
      msg += " with #{@class_name}" if @class_name
      msg + ":\n    " + plain_message
    end

  end

  # This error is raised when an error condition occurs during the creation of a node.
  class NodeCreationError < Error

    def message # :nodoc:
      msg = 'Error while creating a node'
      msg += (@alcn ? " from <#{@alcn}>" : '')
      msg += " with #{@class_name}" if @class_name
      msg + ":\n    " + plain_message
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
      @error_alcn, @line = (error_alcn.kind_of?(Node) ? error_alcn.to_s : error_alcn), line
    end

    def message # :nodoc:
      msg = 'Error '
      if @error_alcn
        msg += "in <#{@error_alcn}"
        msg += ":~#{@line}" if @line
        msg += "> "
      end
      msg += 'while rendering '
      msg += (@alcn ? "<#{@alcn}>" : 'the website')
      msg += " with #{@class_name}" if @class_name
      msg + ":\n    " + plain_message
    end

  end


  # This error is raised when a needed library is not found.
  class LoadError < Error

    # The name of the library that is missing.
    attr_reader :library

    # The name of the Rubygem that provides the missing library.
    attr_reader :gem

    # Create a new LoadError using the provided values.
    #
    # If +library_or_error+ is a String, it is treated as the missing library name and an approriate
    # error message is created. If it is an exception, the exception is wrapped.
    def initialize(library_or_error, class_name = nil, alcn = nil, gem = nil)
      if library_or_error.kind_of?(String)
        msg = "The needed library '#{library_or_error}' is missing."
        msg += " You can install it via rubygems with 'gem install #{gem}'!" if gem
        super(msg, class_name, alcn)
        @library = library_or_error
      else
        super(library_or_error, class_name, alcn)
        @library = nil
      end
      @gem = gem
    end

  end


  # This error is raised when a needed external command is not found.
  class CommandNotFoundError < Error

    # The command that is missing.
    attr_reader :cmd

    # Create a new CommandNotFoundError using the provided values.
    #
    # The parameter +cmd+ specifies the command that is missing.
    def initialize(cmd, class_name = nil, alcn = nil)
      super("The needed command '#{cmd}' is missing!", class_name, alcn)
      @cmd = cmd
    end

  end

end
