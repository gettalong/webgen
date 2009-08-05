# -*- encoding: utf-8 -*-
require 'tempfile'

module Webgen::ContentProcessor

  # Uses the external +xmllint+ program to check if the content is valid (X)HTML.
  class Xmllint

    include Webgen::Loggable

    # Checks the content of +context+ with the +xmllint+ program for validness.
    def call(context)
      error_file = Tempfile.new('webgen-xmllint')
      error_file.close

      `xmllint --version 2>&1`
      if $?.exitstatus != 0
        raise Webgen::CommandNotFoundError.new('xmllint', self.class.name, context.dest_node.alcn)
      end

      cmd = "xmllint #{context.website.config['contentprocessor.xmllint.options']} - 2>'#{error_file.path}'"
      result = IO.popen(cmd, 'r+') do |io|
        io.write(context.content)
        io.close_write
        io.read
      end
      if $?.exitstatus != 0
        File.read(error_file.path).scan(/^-:(\d+):(.*?\n)(.*?\n)/).each do |line, error_msg, line_context|
          log(:warn) { "xmllint reported problems for <#{context.dest_node.alcn}:~#{line}>: #{error_msg.strip} (context: #{line_context.strip})" }
        end
      end
      context
    end

  end

end
