# -*- encoding: utf-8 -*-
require 'tempfile'

module Webgen::ContentProcessor

  # Uses the external +tidy+ program to format the content as valid (X)HTML.
  class Tidy

    include Webgen::Loggable

    # Process the content of +context+ with the +tidy+ program.
    def call(context)
      error_file = Tempfile.new('webgen-tidy')
      error_file.close

      `tidy -v 2>&1`
      if $?.exitstatus != 0
        raise Webgen::CommandNotFoundError.new('tidy', self.class.name, context.dest_node.alcn)
      end

      cmd = "tidy -q -f #{error_file.path} #{context.website.config['contentprocessor.tidy.options']}"
      result = IO.popen(cmd, 'r+') do |io|
        io.write(context.content)
        io.close_write
        io.read
      end
      if $?.exitstatus != 0
        File.readlines(error_file.path).each do |line|
          log($?.exitstatus == 1 ? :warn : :error) { "Tidy reported problems for <#{context.dest_node.alcn}>: #{line}" }
        end
      end
      context.content = result
      context
    end

  end

end
