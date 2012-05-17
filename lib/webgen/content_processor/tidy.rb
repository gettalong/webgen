# -*- encoding: utf-8 -*-

require 'webgen/content_processor'
require 'webgen/utils/external_command'

module Webgen
  class ContentProcessor

    # Uses the external +tidy+ program to format the content as valid (X)HTML.
    module Tidy

      # Process the content of +context+ with the +tidy+ program.
      def self.call(context)
        Webgen::Utils::ExternalCommand.ensure_available!('tidy', '-v')

        cmd = "tidy -q #{context.website.config['content_processor.tidy.options']}"
        status, stdout, stderr = systemu(cmd, 'stdin' => context.content)
        if status.exitstatus != 0
          stderr.split(/\n/).each do |line|
            context.website.logger.send(status.exitstatus == 1 ? :warn : :error) do
              "Tidy reported problems for <#{context.dest_node.alcn}>: #{line}"
            end
          end
        end
        context.content = stdout
        context
      end

    end

  end
end
