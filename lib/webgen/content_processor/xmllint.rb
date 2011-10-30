# -*- encoding: utf-8 -*-

require 'tempfile'
require 'webgen/content_processor'

module Webgen
  class ContentProcessor

    # Uses the external +xmllint+ program to check if the content is valid (X)HTML.
    module Xmllint

      # Checks the content of +context+ with the +xmllint+ program for validness.
      def self.call(context)
        error_file = Tempfile.new('webgen-xmllint')
        error_file.close

        `xmllint --version 2>&1`
        if $?.exitstatus != 0
          raise Webgen::CommandNotFoundError.new('xmllint', self.class.name, context.dest_node)
        end

        cmd = "xmllint #{context.website.config['content_processor.xmllint.options']} - 2>'#{error_file.path}'"
        result = IO.popen(cmd, 'r+') do |io|
          io.write(context.content)
          io.close_write
          io.read
        end
        if $?.exitstatus != 0
          File.read(error_file.path).scan(/^-:(\d+):(.*?\n)(.*?\n)/).each do |line, error_msg, line_context|
            context.website.logger.warn do
              "xmllint reported problems for <#{context.dest_node.alcn}:~#{line}>: #{error_msg.strip} (context: #{line_context.strip})"
            end
          end
        end
        context
      end

    end

  end
end
