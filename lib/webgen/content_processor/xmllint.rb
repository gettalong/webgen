# -*- encoding: utf-8 -*-

require 'webgen/content_processor'
require 'webgen/utils/external_command'

module Webgen
  class ContentProcessor

    # Uses the external +xmllint+ program to check if the content is valid (X)HTML.
    module Xmllint

      # Checks the content of +context+ with the +xmllint+ program for validness.
      def self.call(context)
        Webgen::Utils::ExternalCommand.ensure_available!('xmllint', '--version')

        cmd = "xmllint #{context.website.config['content_processor.xmllint.options']} -"
        status, stdout, stderr = systemu(cmd, 'stdin' => context.content)
        if status.exitstatus != 0
          stderr.scan(/^-:(\d+):(.*?\n)(.*?\n)/).each do |line, error_msg, line_context|
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
